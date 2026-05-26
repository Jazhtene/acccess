"""Admin-only endpoints for dashboard, requests, and media oversight."""

from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.config import settings

from app.api.deps import require_admin
from app.crud import analytics as analytics_crud
from app.crud import system_branding as branding_crud
from app.crud import archive as archive_crud
from app.crud import documentation_request as req_crud
from app.crud import evaluation as eval_crud
from app.crud import event_calendar as event_crud
from app.crud import feedback as feedback_crud
from app.crud import media as media_crud
from app.crud import roles as roles_crud
from app.database import get_db
from app.models.user import User
from app.schemas.common import MessageResponse
from app.utils.timestamps import first_timestamp_iso

router = APIRouter(prefix="/admin", tags=["Admin"])


def _load_error(label: str, exc: Exception) -> HTTPException:
    return HTTPException(
        status_code=500,
        detail={
            "success": False,
            "message": f"Unable to load {label}",
            "details": str(exc),
        },
    )


def _display_status(status: str) -> str:
    return status.strip().lower().capitalize()


def _request_to_json(row) -> dict:
    requestor = row.requestor
    return {
        "request_id": row.id,
        "requester_id": row.requestor_id,
        "requester_name": requestor.fullname if requestor else "Unknown",
        "type": "Documentation",
        "event_name": row.title,
        "title": row.title,
        "event_date": row.event_date.isoformat() if row.event_date else None,
        "venue": row.venue,
        "details": row.description,
        "status": _display_status(row.status),
        "rejection_reason": row.rejection_reason,
        "created_at": row.created_at.isoformat() if row.created_at else None,
    }


def _media_json(m) -> dict:
    ev = m.evaluations[-1] if m.evaluations else None
    ai = m.ai_detection_results[-1] if m.ai_detection_results else None
    uploader = m.uploader
    return {
        "id": m.id,
        "file_name": m.file_name,
        "file_type": m.file_type,
        "file_url": m.file_url,
        "request_id": m.request_id,
        "uploaded_by": m.uploaded_by,
        "uploader_name": uploader.fullname if uploader else "Unknown",
        "uploaded_at": m.uploaded_at.isoformat() if m.uploaded_at else None,
        "overall_score": ev.overall_score if ev else None,
        "ai_detected": ai.detection_result == "ai_generated" if ai else False,
        "ai_probability": ai.ai_probability if ai else None,
    }


@router.get("/stats")
def admin_stats(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return analytics_crud.dashboard_stats(db)


@router.get("/roles")
def list_roles(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    """Default roles (Admin, Member, Organization) from PostgreSQL `roles` table."""
    try:
        return roles_crud.list_roles_with_stats(db)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "success": False,
                "message": "Unable to load roles",
                "details": str(exc),
            },
        ) from exc


@router.get("/analytics/reports")
def list_analytics_reports(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    """Published dashboard snapshots stored in PostgreSQL."""
    return analytics_crud.list_analytics_reports(db)


@router.get("/service-requests")
def list_service_requests(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    rows = req_crud.list_all(db)
    return [_request_to_json(r) for r in rows]


@router.get("/media")
def list_all_media(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    """All uploaded media for admin repository / upload review."""
    rows = media_crud.list_media(db)
    return [_media_json(m) for m in rows]


class EvaluationRemarksUpdate(BaseModel):
    admin_remarks: str | None = Field(None, max_length=2000)


def _evaluation_json(db: Session, ev) -> dict:
    media = ev.media
    uploader = media.uploader if media else None
    ai = eval_crud.get_ai_for_media(db, ev.media_id)
    name = media.file_name if media else ""
    member = uploader.fullname if uploader else "Unknown"
    return {
        "id": ev.id,
        "media_id": ev.media_id,
        "media_name": name,
        "file_name": name,
        "file_url": media.file_url if media else "",
        "member_name": member,
        "uploader_name": member,
        "sharpness_score": ev.sharpness_score,
        "brightness_score": ev.brightness_score,
        "contrast_score": ev.contrast_score,
        "blur_score": ev.blur_score,
        "noise_score": ev.noise_score,
        "overall_score": ev.overall_score,
        "admin_remarks": ev.feedback,
        "feedback": ev.feedback,
        "quality_level": ev.quality_level,
        "recommendation": ev.recommendation,
        "criteria_json": ev.criteria_json,
        "created_at": first_timestamp_iso(ev, "evaluated_at"),
        "evaluated_at": first_timestamp_iso(ev, "evaluated_at"),
        "updated_at": first_timestamp_iso(ev, "evaluated_at"),
        "ai_probability": ai.ai_probability if ai else None,
        "ai_result": ai.detection_result if ai else None,
        "detection_result": ai.detection_result if ai else None,
    }


@router.get("/evaluations/summary")
def evaluations_summary(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return eval_crud.summary_stats(db)


@router.get("/evaluations")
def list_all_evaluations(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    try:
        rows = eval_crud.list_all(db)
        return [_evaluation_json(db, ev) for ev in rows]
    except Exception as exc:
        raise _load_error("media evaluations", exc) from exc


@router.patch("/evaluations/{evaluation_id}")
def update_evaluation_remarks(
    evaluation_id: int,
    body: EvaluationRemarksUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    ev = eval_crud.get_by_id(db, evaluation_id)
    if not ev:
        raise HTTPException(status_code=404, detail="Evaluation not found")
    eval_crud.update_feedback(db, ev, body.admin_remarks)
    return _evaluation_json(db, ev)


@router.post("/evaluations/{evaluation_id}/archive", response_model=MessageResponse)
def archive_evaluated_media(
    evaluation_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    ev = eval_crud.get_by_id(db, evaluation_id)
    if not ev:
        raise HTTPException(status_code=404, detail="Evaluation not found")
    archive_crud.create(db, {"media_id": ev.media_id}, admin.id)
    return MessageResponse(message="Media archived successfully")


@router.delete("/media/{media_id}", response_model=MessageResponse)
def delete_media(
    media_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    media = media_crud.get(db, media_id)
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
    media_crud.delete_media(db, media)
    return MessageResponse(message="Media deleted successfully")


class AiDetectionReviewUpdate(BaseModel):
    review_status: str | None = Field(None, max_length=40)
    admin_remarks: str | None = Field(None, max_length=2000)


def _confidence_level(score: float) -> str:
    pct = score * 100
    if pct >= 80:
        return "high"
    if pct >= 50:
        return "medium"
    return "low"


def _ai_detection_json(ai) -> dict:
    media = ai.media
    uploader = media.uploader if media else None
    name = media.file_name if media else ""
    url = media.file_url if media else ""
    result = ai.detection_result or ""
    is_ai = "ai" in result.lower() or "generated" in result.lower()
    confidence = ai.ai_probability if is_ai else (1.0 - ai.ai_probability)
    review_status = getattr(ai, "review_status", None) or "pending_review"
    if not review_status and ai.reviewed_by_admin:
        review_status = "verified_human" if not is_ai else "verified_ai_generated"
    return {
        "id": ai.id,
        "media_id": ai.media_id,
        "media_name": name,
        "file_name": name,
        "media_url": url,
        "file_url": url,
        "thumbnail_url": url,
        "member_name": uploader.fullname if uploader else "Unknown",
        "uploader_name": uploader.fullname if uploader else "Unknown",
        "ai_result": result,
        "detection_result": result,
        "ai_probability": ai.ai_probability,
        "confidence_score": round(confidence, 3),
        "confidence_level": _confidence_level(confidence),
        "review_status": review_status,
        "reviewed_by_admin": ai.reviewed_by_admin,
        "admin_remarks": getattr(ai, "admin_remarks", None),
        "detection_remarks": getattr(ai, "detection_remarks", None),
        "member_id": uploader.id if uploader else None,
        "reviewed_by": getattr(ai, "reviewed_by", None),
        "reviewed_at": ai.reviewed_at.isoformat() if getattr(ai, "reviewed_at", None) else None,
        "created_at": first_timestamp_iso(ai, "created_at"),
        "updated_at": first_timestamp_iso(ai, "updated_at", "reviewed_at", "created_at"),
        "scanned_at": first_timestamp_iso(ai, "created_at"),
    }


@router.get("/ai-detection/summary")
def ai_detection_summary(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return eval_crud.ai_detection_summary(db)


@router.get("/ai-detection")
def list_ai_detection(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    try:
        rows = eval_crud.list_all_ai(db)
        return [_ai_detection_json(ai) for ai in rows]
    except Exception as exc:
        raise _load_error("AI detection results", exc) from exc


@router.patch("/ai-detection/{ai_id}")
def update_ai_detection_review(
    ai_id: int,
    body: AiDetectionReviewUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    row = eval_crud.get_ai_by_id(db, ai_id)
    if not row:
        raise HTTPException(status_code=404, detail="AI detection record not found")
    eval_crud.update_ai_review(
        db,
        row,
        review_status=body.review_status,
        admin_remarks=body.admin_remarks,
        reviewed_by=admin.id,
    )
    return _ai_detection_json(row)


@router.get("/ai-detection/{ai_id}/history")
def ai_detection_review_history(
    ai_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    from app.services.ai_review_workflow import history_to_json, list_review_history

    row = eval_crud.get_ai_by_id(db, ai_id)
    if not row:
        raise HTTPException(status_code=404, detail="AI detection record not found")
    history = list_review_history(db, ai_id)
    out = []
    for h in history:
        reviewer_name = h.reviewer.fullname if h.reviewer else None
        out.append(history_to_json(h, reviewer_name))
    return out


@router.post("/ai-detection/{ai_id}/archive", response_model=MessageResponse)
def archive_ai_detection_media(
    ai_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    row = eval_crud.get_ai_by_id(db, ai_id)
    if not row:
        raise HTTPException(status_code=404, detail="AI detection record not found")
    archive_crud.create(db, {"media_id": row.media_id}, admin.id)
    return MessageResponse(message="Media archived successfully")


@router.get("/tasks")
def list_all_tasks(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    from sqlalchemy import select
    from sqlalchemy.orm import joinedload

    from app.models.request_assignment import RequestAssignment

    rows = list(
        db.scalars(
            select(RequestAssignment)
            .options(
                joinedload(RequestAssignment.request),
                joinedload(RequestAssignment.member),
            )
            .order_by(RequestAssignment.id.desc())
        )
    )
    return [
        {
            "id": r.id,
            "request_id": r.request_id,
            "request_title": r.request.title if r.request else "",
            "member_id": r.member_id,
            "member_name": r.member.fullname if r.member else "Unknown",
            "task_role": r.task_role,
            "status": r.status,
            "event_date": r.request.event_date.isoformat() if r.request and r.request.event_date else None,
        }
        for r in rows
    ]


@router.get("/events")
def list_all_events(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    try:
        rows = event_crud.list_events(db)
        return [event_crud.event_to_json(e) for e in rows]
    except Exception as exc:
        raise _load_error("calendar events", exc) from exc


class EventCreateBody(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str | None = Field(None, max_length=5000)
    event_date: str
    end_date: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    location: str | None = Field(None, max_length=200)
    status: str = Field("upcoming", max_length=40)
    assigned_member_id: int | None = None
    documentation_request_id: int | None = None
    admin_remarks: str | None = Field(None, max_length=2000)


class EventUpdateBody(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = Field(None, max_length=5000)
    event_date: str | None = None
    end_date: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    location: str | None = Field(None, max_length=200)
    status: str | None = Field(None, max_length=40)
    assigned_member_id: int | None = None
    documentation_request_id: int | None = None
    admin_remarks: str | None = Field(None, max_length=2000)


@router.post("/events")
def create_event(
    body: EventCreateBody,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    start = event_crud.parse_date(body.event_date)
    if not start:
        raise HTTPException(status_code=400, detail="Invalid event_date")
    start_t = event_crud.parse_time(body.start_time)
    end_t = event_crud.parse_time(body.end_time)
    if start_t and end_t and start_t >= end_t:
        raise HTTPException(status_code=400, detail="start_time must be before end_time")
    row = event_crud.create_event(
        db,
        {
            "title": body.title.strip(),
            "description": body.description,
            "start_date": start,
            "end_date": event_crud.parse_date(body.end_date) if body.end_date else None,
            "start_time": start_t,
            "end_time": end_t,
            "venue": body.location,
            "status": body.status,
            "assigned_member_id": body.assigned_member_id,
            "request_id": body.documentation_request_id,
            "admin_remarks": body.admin_remarks,
        },
    )
    if body.assigned_member_id:
        from app.services import notification_events as notify_events

        notify_events.notify_event_member_assigned(
            db,
            event_id=row.id,
            event_title=row.title,
            member_id=body.assigned_member_id,
            event_date=body.event_date,
        )
    return event_crud.event_to_json(row)


@router.patch("/events/{event_id}")
def update_event(
    event_id: int,
    body: EventUpdateBody,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    row = event_crud.get_event(db, event_id)
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")
    previous_member_id = row.assigned_member_id
    data: dict = {}
    if body.title is not None:
        data["title"] = body.title.strip()
    if body.description is not None:
        data["description"] = body.description
    if body.event_date is not None:
        parsed = event_crud.parse_date(body.event_date)
        if not parsed:
            raise HTTPException(status_code=400, detail="Invalid event_date")
        data["start_date"] = parsed
    if body.end_date is not None:
        data["end_date"] = event_crud.parse_date(body.end_date)
    if body.start_time is not None:
        data["start_time"] = event_crud.parse_time(body.start_time)
    if body.end_time is not None:
        data["end_time"] = event_crud.parse_time(body.end_time)
    if body.location is not None:
        data["venue"] = body.location
    if body.status is not None:
        data["status"] = body.status
    if body.assigned_member_id is not None:
        data["assigned_member_id"] = body.assigned_member_id
    if body.documentation_request_id is not None:
        data["request_id"] = body.documentation_request_id
    if body.admin_remarks is not None:
        data["admin_remarks"] = body.admin_remarks
    start_t = data.get("start_time", row.start_time)
    end_t = data.get("end_time", row.end_time)
    if start_t and end_t and start_t >= end_t:
        raise HTTPException(status_code=400, detail="start_time must be before end_time")
    updated = event_crud.update_event(db, row, data)
    new_member_id = updated.assigned_member_id
    if new_member_id and new_member_id != previous_member_id:
        from app.services import notification_events as notify_events

        notify_events.notify_event_member_assigned(
            db,
            event_id=updated.id,
            event_title=updated.title,
            member_id=new_member_id,
            event_date=updated.start_date.isoformat() if updated.start_date else None,
        )
    return event_crud.event_to_json(updated)


@router.delete("/events/{event_id}", response_model=MessageResponse)
def delete_event(
    event_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    row = event_crud.get_event(db, event_id)
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")
    event_crud.delete_event(db, row)
    return MessageResponse(message="Event deleted successfully")


@router.get("/feedback")
def list_all_feedback(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    rows = feedback_crud.list_feedbacks(db)
    return [
        {
            "id": f.id,
            "request_id": f.request_id,
            "event_title": f.request.title if f.request else None,
            "event_name": f.request.title if f.request else None,
            "user_id": f.user_id,
            "member_name": f.user.fullname if f.user else "Unknown",
            "user_name": f.user.fullname if f.user else "Unknown",
            "rating": f.rating,
            "comment": f.comment,
            "created_at": f.created_at.isoformat() if f.created_at else None,
        }
        for f in rows
    ]


LOGO_ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".webp"}


def _branding_upload_dir() -> Path:
    path = Path(settings.upload_dir) / "branding"
    path.mkdir(parents=True, exist_ok=True)
    return path


@router.get("/branding")
def admin_get_branding(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    from app.models.system_branding import SystemBranding

    payload = branding_crud.branding_payload(db)
    updated_by = None
    try:
        row = db.get(SystemBranding, branding_crud.BRANDING_ROW_ID)
        if row and row.updater:
            updated_by = row.updater.fullname
    except Exception:
        db.rollback()
    return {**payload, "updated_by": updated_by}


@router.post("/branding/logo")
async def admin_upload_logo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    ext = Path(file.filename or "").suffix.lower()
    if ext not in LOGO_ALLOWED_EXT:
        raise HTTPException(
            status_code=400,
            detail="Logo must be JPG, JPEG, PNG, or WEBP.",
        )

    content = await file.read()
    max_bytes = 5 * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=400, detail="Logo must be 5 MB or smaller.")

    dest_dir = _branding_upload_dir()
    for old in dest_dir.glob("access_logo.*"):
        try:
            old.unlink()
        except OSError:
            pass

    filename = f"access_logo{ext if ext != '.jpeg' else '.jpg'}"
    dest = dest_dir / filename
    dest.write_bytes(content)

    logo_path = f"/uploads/branding/{filename}"
    branding_crud.set_logo(db, logo_path, admin.id)
    payload = branding_crud.branding_payload(db)
    return {"message": "Logo updated successfully.", **payload, "updated_by": admin.fullname}


class BrandingNamesBody(BaseModel):
    app_name: str | None = Field(None, max_length=120)
    tagline: str | None = Field(None, max_length=255)
    short_tagline: str | None = Field(None, max_length=255)
    organization: str | None = Field(None, max_length=120)


@router.patch("/branding/names")
def admin_update_branding_names(
    body: BrandingNamesBody,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    branding_crud.update_names(
        db,
        user_id=admin.id,
        app_name=body.app_name,
        tagline=body.tagline,
        short_tagline=body.short_tagline,
        organization=body.organization,
    )
    payload = branding_crud.branding_payload(db)
    return {
        "message": "System names updated.",
        **payload,
        "updated_by": admin.fullname,
    }


@router.delete("/branding/names")
def admin_reset_branding_names(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    branding_crud.reset_names(db, admin.id)
    payload = branding_crud.branding_payload(db)
    return {
        "message": "System names reset to defaults.",
        **payload,
        "updated_by": admin.fullname,
    }


@router.delete("/branding/logo")
def admin_reset_logo(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    dest_dir = _branding_upload_dir()
    for old in dest_dir.glob("access_logo.*"):
        try:
            old.unlink()
        except OSError:
            pass
    branding_crud.clear_logo(db, admin.id)
    payload = branding_crud.branding_payload(db)
    return {"message": "Logo reset to default bundled asset.", **payload, "updated_by": admin.fullname}
