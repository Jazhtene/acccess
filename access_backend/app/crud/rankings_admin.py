"""Enriched member rankings for admin leaderboard."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.crud import member_profile as profile_crud
from app.models.ai_detection_result import AiDetectionResult
from app.models.enums import RoleName, UserStatus
from app.models.media_file import MediaFile
from app.models.role import Role
from app.models.user import User
from app.services.skill_scoring import build_skill_payload


def _ai_counts(db: Session, user_id: int) -> tuple[int, int, int]:
    """Returns (human_verified, ai_confirmed, suspicious) based on admin review when available."""
    rows = db.execute(
        select(
            AiDetectionResult.detection_result,
            AiDetectionResult.ai_probability,
            AiDetectionResult.review_status,
        )
        .join(MediaFile, AiDetectionResult.media_id == MediaFile.id)
        .where(MediaFile.uploaded_by == user_id)
    ).all()
    human = ai_gen = suspicious = 0
    for result, prob, review_status in rows:
        status = (review_status or "pending_review").lower()
        if status in ("verified_human", "accepted_with_warning"):
            human += 1
            continue
        if status in ("confirmed_ai_generated", "verified_ai_generated", "rejected"):
            ai_gen += 1
            continue
        if status in ("needs_further_review", "reupload_requested", "pending_review"):
            label = (result or "").lower()
            if "ai" in label or "generated" in label:
                suspicious += 1
            elif prob >= 0.18:
                suspicious += 1
            else:
                human += 1
            continue
        label = (result or "").lower()
        if "ai" in label or "generated" in label:
            ai_gen += 1
        elif prob >= 0.18:
            suspicious += 1
        else:
            human += 1
    return human, ai_gen, suspicious


def _ai_summary(human: int, ai_gen: int, suspicious: int) -> str:
    if human + ai_gen + suspicious == 0:
        return "No scans yet"
    parts = []
    if human:
        parts.append(f"{human} human")
    if ai_gen:
        parts.append(f"{ai_gen} AI")
    if suspicious:
        parts.append(f"{suspicious} suspicious")
    return ", ".join(parts)


def _participation_status(
    *,
    uploads: int,
    avg_score: float,
    ai_gen: int,
    suspicious: int,
    last_activity: datetime | None,
) -> str:
    if ai_gen > 0 or suspicious >= 2:
        return "under_review"
    if uploads == 0:
        return "inactive"
    if avg_score > 0 and avg_score < 0.60:
        return "needs_training"
    if uploads < 2 and avg_score < 0.70:
        return "needs_training"
    if last_activity:
        cutoff = datetime.now(timezone.utc) - timedelta(days=30)
        la = last_activity if last_activity.tzinfo else last_activity.replace(tzinfo=timezone.utc)
        if la < cutoff:
            return "inactive"
    return "active"


def list_rankings(db: Session) -> list[dict]:
    members = db.scalars(
        select(User)
        .options(joinedload(User.role), joinedload(User.member_ranking))
        .where(User.status == UserStatus.APPROVED, User.role.has(Role.role_name == RoleName.MEMBER))
    ).all()

    result: list[dict] = []
    for u in members:
        ranking = u.member_ranking
        points = ranking.total_points if ranking else 0
        total_uploads = profile_crud.uploads_count(db, u.id)
        approved_uploads = profile_crud.approved_uploads_count(db, u.id)
        _, avg_score = profile_crud.evaluations_stats(db, u.id)
        completed_tasks = profile_crud.assignments_completed(db, u.id)
        assigned_tasks = profile_crud.assignments_total(db, u.id)
        admin_eval = profile_crud.admin_evaluation_score(db, u.id)
        human, ai_gen, suspicious = _ai_counts(db, u.id)
        total_checked = human + ai_gen + suspicious
        last_upload = db.scalar(
            select(func.max(MediaFile.uploaded_at)).where(MediaFile.uploaded_by == u.id)
        )
        last_activity = last_upload or (ranking.updated_at if ranking else None)
        status = _participation_status(
            uploads=total_uploads,
            avg_score=avg_score,
            ai_gen=ai_gen,
            suspicious=suspicious,
            last_activity=last_activity,
        )

        skill = build_skill_payload(
            average_quality_score=avg_score,
            approved_uploads=approved_uploads,
            total_uploads=total_uploads,
            completed_tasks=completed_tasks,
            assigned_tasks=assigned_tasks,
            admin_evaluation_score=admin_eval,
            human_verified_uploads=human,
            total_checked_uploads=total_checked,
        )

        result.append(
            {
                "id": u.id,
                "user_id": u.id,
                "member_name": u.fullname,
                "name": u.fullname,
                "skill_level": skill["skill_level"],
                "skill_score": skill["skill_score"],
                "points": points,
                "good_evaluations": points,
                "uploads": total_uploads,
                "total_uploads": total_uploads,
                "approved_uploads": approved_uploads,
                "average_quality_score": skill["average_quality_score"],
                "avg_score": round(avg_score, 3),
                "media_quality_score": skill["media_quality_score"],
                "approved_uploads_score": skill["approved_uploads_score"],
                "task_participation_score": skill["task_participation_score"],
                "completed_tasks": completed_tasks,
                "assigned_tasks": assigned_tasks,
                "admin_evaluation_score": skill["admin_evaluation_score"],
                "ai_authenticity_score": skill["ai_authenticity_score"],
                "ai_result_summary": _ai_summary(human, ai_gen, suspicious),
                "ai_human_count": human,
                "ai_flagged_count": ai_gen + suspicious,
                "participation_status": status,
                "last_activity": last_activity.isoformat() if last_activity else None,
                "admin_remarks": ranking.admin_remarks if ranking else None,
                "rank_position": ranking.rank_position if ranking else None,
            }
        )

    result.sort(key=lambda x: (x["skill_score"], x["points"], x["uploads"]), reverse=True)
    for idx, row in enumerate(result, start=1):
        row["rank"] = idx
        row["rank_position"] = idx
    return result


def rankings_summary(rows: list[dict]) -> dict:
    if not rows:
        return {
            "total_ranked": 0,
            "top_performer_name": "—",
            "top_performer_points": 0,
            "most_active_uploader_name": "—",
            "most_active_uploads": 0,
            "needs_improvement_count": 0,
        }

    top = rows[0]
    most_uploads = max(rows, key=lambda r: r["uploads"])
    needs = sum(
        1
        for r in rows
        if r["participation_status"] in ("needs_training", "inactive")
        or (r.get("skill_score") or 0) < 60
    )

    return {
        "total_ranked": len(rows),
        "top_performer_name": top["member_name"],
        "top_performer_points": top["points"],
        "most_active_uploader_name": most_uploads["member_name"],
        "most_active_uploads": most_uploads["uploads"],
        "needs_improvement_count": needs,
    }


def update_admin_remarks(db: Session, user_id: int, remarks: str | None) -> None:
    from app.crud.member_ranking import get_or_create

    row = get_or_create(db, user_id)
    row.admin_remarks = remarks
    db.commit()
