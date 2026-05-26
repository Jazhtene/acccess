"""Admin AI detection review workflow — history, notifications, ranking effects."""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.crud import member_ranking as ranking_crud
from app.models.ai_detection_result import AiDetectionResult
from app.models.ai_review_history import AiReviewHistory
from app.models.media_file import MediaFile

# Statuses that count as admin-confirmed decisions (not auto-detection).
CONFIRMED_AI_STATUSES = frozenset(
    {"confirmed_ai_generated", "verified_ai_generated", "rejected"}
)
VERIFIED_HUMAN_STATUSES = frozenset({"verified_human", "accepted_with_warning"})

NOTIFICATION_MESSAGES: dict[str, tuple[str, str]] = {
    "pending_review": (
        "Media under AI review",
        "Your uploaded media is under AI review. Please wait for admin verification.",
    ),
    "needs_further_review": (
        "Media needs further review",
        "Your uploaded media requires additional admin review. Please wait for verification.",
    ),
    "verified_human": (
        "Media verified as authentic",
        "Your uploaded media has been verified as authentic.",
    ),
    "confirmed_ai_generated": (
        "AI-generated media confirmed",
        "Your uploaded media was confirmed as AI-generated after admin review. See admin remarks.",
    ),
    "verified_ai_generated": (
        "AI-generated media confirmed",
        "Your uploaded media was confirmed as AI-generated after admin review. See admin remarks.",
    ),
    "accepted_with_warning": (
        "Media accepted with warning",
        "Your uploaded media was accepted with a warning after manual review. See admin remarks.",
    ),
    "reupload_requested": (
        "Media reupload requested",
        "Your uploaded media was flagged for AI review. Please reupload the original or valid media file for verification.",
    ),
    "rejected": (
        "Media rejected after AI review",
        "Your uploaded media was rejected after AI review. Please check the admin remarks.",
    ),
}


def _confidence_score(row: AiDetectionResult) -> float:
    result = (row.detection_result or "").lower()
    is_ai = "ai" in result or "generated" in result
    return row.ai_probability if is_ai else (1.0 - row.ai_probability)


def _is_reviewed_status(status: str) -> bool:
    return status not in ("pending_review", "needs_further_review")


def apply_ai_review(
    db: Session,
    row: AiDetectionResult,
    *,
    review_status: str | None = None,
    admin_remarks: str | None = None,
    reviewed_by: int | None = None,
) -> AiDetectionResult:
    previous = row.review_status
    if review_status is not None:
        row.review_status = review_status
    if admin_remarks is not None:
        row.admin_remarks = admin_remarks
    if review_status is not None:
        row.reviewed_by_admin = _is_reviewed_status(review_status)
        row.reviewed_by = reviewed_by
        row.reviewed_at = datetime.now(timezone.utc)

    media = row.media
    member_id = media.uploaded_by if media else None

    if review_status is not None and review_status != previous:
        history = AiReviewHistory(
            ai_detection_id=row.id,
            media_id=row.media_id,
            member_id=member_id,
            ai_result=row.detection_result,
            confidence_score=round(_confidence_score(row), 3),
            previous_status=previous,
            new_status=review_status,
            admin_remarks=row.admin_remarks,
            reviewed_by=reviewed_by,
            reviewed_at=datetime.now(timezone.utc),
        )
        db.add(history)

        if member_id:
            from app.services import notification_events as notify_events

            title, message = NOTIFICATION_MESSAGES.get(
                review_status,
                ("AI review updated", f"Your media review status is now: {review_status.replace('_', ' ')}."),
            )
            if row.admin_remarks:
                message = f"{message} Remarks: {row.admin_remarks[:200]}"
            priority = "high" if review_status in ("rejected", "confirmed_ai_generated", "verified_ai_generated") else "normal"
            notify_events.notify_user(
                db,
                member_id,
                title=title,
                message=message,
                category="ai_detection",
                priority=priority,
                action_type="view_result",
                action_ref_id=row.media_id,
            )

        if member_id and review_status in CONFIRMED_AI_STATUSES:
            ranking_crud.add_points(db, member_id, -25)

    db.commit()
    db.refresh(row)
    return row


def list_review_history(db: Session, ai_id: int) -> list[AiReviewHistory]:
    from sqlalchemy import select
    from sqlalchemy.orm import joinedload

    return list(
        db.scalars(
            select(AiReviewHistory)
            .options(joinedload(AiReviewHistory.reviewer))
            .where(AiReviewHistory.ai_detection_id == ai_id)
            .order_by(AiReviewHistory.reviewed_at.desc())
        )
    )


def history_to_json(h: AiReviewHistory, reviewer_name: str | None = None) -> dict:
    return {
        "id": h.id,
        "media_id": h.media_id,
        "member_id": h.member_id,
        "ai_result": h.ai_result,
        "confidence_score": h.confidence_score,
        "previous_status": h.previous_status,
        "new_status": h.new_status,
        "admin_remarks": h.admin_remarks,
        "reviewed_by": h.reviewed_by,
        "reviewed_by_name": reviewer_name,
        "reviewed_at": h.reviewed_at.isoformat() if h.reviewed_at else None,
    }


def initial_review_status(detection_result: str, ai_probability: float) -> str:
    """Set fair initial status after automated scan — never auto-reject."""
    label = (detection_result or "").lower()
    if "ai" in label or "generated" in label:
        return "pending_review"
    if ai_probability >= 0.18:
        return "needs_further_review"
    # Low confidence human scan
    if ai_probability >= 0.12:
        return "pending_review"
    return "pending_review"
