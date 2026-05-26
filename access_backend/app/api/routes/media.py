"""Media uploads and repository."""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.config import settings
from app.crud import media as media_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import MediaOut
from app.services.media_pipeline import run_pipeline

router = APIRouter(prefix="/media", tags=["Media"])

ALLOWED_IMAGE = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
ALLOWED_VIDEO = {".mp4", ".mov", ".avi", ".webm"}


def _ensure_upload_dir() -> Path:
    path = Path(settings.upload_dir)
    path.mkdir(parents=True, exist_ok=True)
    (path / "images").mkdir(exist_ok=True)
    (path / "videos").mkdir(exist_ok=True)
    return path


def _media_out(m, base_url: str | None = None) -> MediaOut:
    ev = m.evaluations[-1] if m.evaluations else None
    ai = m.ai_detection_results[-1] if m.ai_detection_results else None
    url = m.file_url
    if base_url and url.startswith("/"):
        url = f"{base_url}{url}"
    return MediaOut(
        id=m.id,
        uploaded_by=m.uploaded_by,
        request_id=m.request_id,
        file_name=m.file_name,
        file_type=m.file_type,
        file_url=url,
        uploaded_at=m.uploaded_at,
        overall_score=ev.overall_score if ev else None,
        ai_detected=ai.detection_result == "ai_generated" if ai else False,
        ai_probability=ai.ai_probability if ai else None,
        feedback=ev.feedback if ev else None,
    )


@router.get("", response_model=list[MediaOut])
def list_media(
    file_type: str | None = None,
    search: str | None = None,
    mine: bool = False,
    request_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    uploaded_by = current_user.id if mine else None
    items = media_crud.list_media(
        db,
        uploaded_by=uploaded_by,
        file_type=file_type,
        search=search,
        request_id=request_id,
    )
    return [_media_out(m) for m in items]


@router.get("/{media_id}", response_model=MediaOut)
def get_media(
    media_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    m = media_crud.get(db, media_id)
    if not m:
        raise HTTPException(status_code=404, detail="Media not found")
    return _media_out(m)


@router.post("/upload", response_model=MediaOut)
async def upload_media(
    file: UploadFile = File(...),
    request_id: int = Form(...),
    file_name: str | None = Form(None),
    evaluation_metadata: str | None = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    ext = Path(file.filename or "").suffix.lower()
    is_video = ext in ALLOWED_VIDEO
    is_image = ext in ALLOWED_IMAGE
    if not is_video and not is_image:
        raise HTTPException(status_code=400, detail="Unsupported file type")

    content = await file.read()
    max_bytes = settings.max_upload_mb * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=400, detail=f"File exceeds {settings.max_upload_mb}MB limit")

    upload_root = _ensure_upload_dir()
    sub = "videos" if is_video else "images"
    filename = f"{uuid.uuid4().hex}{ext}"
    rel_path = f"{sub}/{filename}"
    dest = upload_root / rel_path
    dest.write_bytes(content)

    display_name = (file_name or file.filename or filename).strip()[:255]
    file_type = "video" if is_video else "photo"
    row = media_crud.create(
        db,
        {
            "uploaded_by": current_user.id,
            "request_id": request_id,
            "file_name": display_name,
            "file_type": file_type,
            "file_url": f"/uploads/{rel_path}",
        },
    )
    row = media_crud.get(db, row.id)
    run_pipeline(db, row, content, evaluation_metadata=evaluation_metadata)  # type: ignore[arg-type]
    row = media_crud.get(db, row.id)
    return _media_out(row)  # type: ignore[arg-type]
