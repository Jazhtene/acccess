"""Auto quality evaluation + AI detection when media is uploaded."""

from __future__ import annotations

import json

from sqlalchemy.orm import Session

from app.crud import evaluation as eval_crud
from app.crud import member_ranking as ranking_crud
from app.crud import user as user_crud
from app.models.ai_detection_result import AiDetectionResult
from app.models.media_evaluation import MediaEvaluation
from app.models.media_file import MediaFile
from app.services.image_quality import (
    analyze_bytes,
    legacy_scores_from_payload,
    parse_client_payload,
)


def run_pipeline(
    db: Session,
    media: MediaFile,
    file_bytes: bytes,
    *,
    evaluation_metadata: str | None = None,
) -> tuple[MediaEvaluation, AiDetectionResult]:
    client = parse_client_payload(evaluation_metadata)
    if client:
        payload = client
        scores = legacy_scores_from_payload(payload)
        feedback = payload.get("ai_feedback") or _feedback_text(scores["overall_score"], "human")
        criteria_json = json.dumps(payload)
        quality_level = payload.get("quality_level")
        recommendation = payload.get("recommendation")
        ai_info = payload.get("ai_detection") if isinstance(payload.get("ai_detection"), dict) else {}
    else:
        analyzed = analyze_bytes(file_bytes)
        if analyzed:
            payload = analyzed
            scores = analyzed["legacy"]
            feedback = analyzed.get("ai_feedback") or _feedback_text(scores["overall_score"], "human")
            criteria_json = json.dumps(analyzed)
            quality_level = analyzed.get("quality_level")
            recommendation = analyzed.get("recommendation")
            ai_info = analyzed.get("ai_detection") or {}
        else:
            scores = {
                "sharpness_score": 0.5,
                "brightness_score": 0.5,
                "contrast_score": 0.5,
                "blur_score": 0.5,
                "noise_score": 0.5,
                "overall_score": 0.5,
            }
            feedback = "Unable to analyze image bytes. Officers will review manually."
            criteria_json = None
            quality_level = "Fair"
            recommendation = "For Officer Review"
            ai_info = {}

    ai_prob, ai_label, detection_remarks = _ai_from_payload(ai_info)

    evaluation = eval_crud.create_evaluation(
        db,
        {
            "media_id": media.id,
            **scores,
            "feedback": feedback,
            "criteria_json": criteria_json,
            "quality_level": quality_level,
            "recommendation": recommendation,
        },
    )
    from app.services.ai_review_workflow import initial_review_status

    review_status = initial_review_status(ai_label, ai_prob)
    ai_row = eval_crud.create_ai_result(
        db,
        {
            "media_id": media.id,
            "ai_probability": ai_prob,
            "detection_result": ai_label,
            "reviewed_by_admin": False,
            "review_status": review_status,
            "detection_remarks": detection_remarks,
        },
    )

    if media.uploaded_by:
        user = user_crud.get_by_id(db, media.uploaded_by)
        uploader_name = user.fullname if user else "Member"
        if user:
            user_crud.update_skill_from_evaluation(db, user, scores["overall_score"])
            ranking_crud.add_points(db, media.uploaded_by, int(scores["overall_score"] * 100))

        from app.services import notification_events as notify_events

        notify_events.notify_media_uploaded(db, media.id, media.file_name, uploader_name)
        if user:
            notify_events.notify_media_evaluated(
                db,
                media.uploaded_by,
                media.id,
                media.file_name,
                int(scores["overall_score"] * 100),
            )
        if ai_label == "ai_generated" or ai_prob >= 0.18:
            notify_events.notify_ai_detection_alert(
                db,
                media.id,
                media.file_name,
                uploader_name,
                member_id=media.uploaded_by,
            )

    return evaluation, ai_row


def _ai_from_payload(ai_info: dict) -> tuple[float, str, str]:
    verdict = str(ai_info.get("verdict", "authentic")).lower()
    confidence = float(ai_info.get("confidence", 0.85))
    detail = str(ai_info.get("detail", ""))
    if verdict == "suspicious":
        return round(min(0.74, confidence), 3), "suspicious", detail or (
            "Suspicious indicators detected. Officers will review this submission carefully."
        )
    if verdict in ("ai_generated", "ai"):
        return round(max(0.75, confidence), 3), "ai_generated", detail or (
            "Possible AI-generated content flagged for officer review."
        )
    return round(min(0.35, confidence * 0.4), 3), "human", detail or (
        "Automated scan indicates authentic human-uploaded media."
    )


def _feedback_text(overall: float, ai_result: str) -> str:
    if ai_result == "ai_generated":
        return "Possible AI-generated content detected. Officers will review this submission."
    if overall >= 0.85:
        return "Excellent quality. Sharp focus and balanced exposure."
    if overall >= 0.70:
        return "Good submission. Minor improvements possible in lighting or contrast."
    if overall >= 0.50:
        return "Acceptable quality. Try steadier shots and better lighting."
    return "Quality below target. Retake with more light and reduce motion blur."
