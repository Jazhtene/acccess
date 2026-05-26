"""Current-user profile API (alias for mobile/web clients)."""

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pathlib import Path
import uuid

from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.api.routes.member import _profile_out, apply_profile_update
from app.config import settings
from app.crud import member_profile as profile_crud
from app.crud import user as user_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import ProfileOut, ProfileUpdate

router = APIRouter(prefix="/profile", tags=["Profile"])

ALLOWED_AVATAR = {".jpg", ".jpeg", ".png", ".webp", ".gif"}


@router.get("", response_model=ProfileOut)
def get_profile(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    user = user_crud.get_by_id(db, current_user.id)
    return _profile_out(db, user)  # type: ignore[arg-type]


@router.put("", response_model=ProfileOut)
def put_profile(
    body: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    return apply_profile_update(db, current_user, body)


@router.patch("", response_model=ProfileOut)
def patch_profile(
    body: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    return apply_profile_update(db, current_user, body)


@router.post("/avatar", response_model=ProfileOut)
async def upload_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    ext = Path(file.filename or "").suffix.lower()
    if ext not in ALLOWED_AVATAR:
        raise HTTPException(status_code=400, detail="Use JPG, PNG, WEBP, or GIF")

    content = await file.read()
    max_bytes = min(settings.max_upload_mb, 10) * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=400, detail="Image is too large")

    upload_root = Path(settings.upload_dir)
    upload_root.mkdir(parents=True, exist_ok=True)
    sub = upload_root / "profiles"
    sub.mkdir(parents=True, exist_ok=True)
    filename = f"user_{current_user.id}_{uuid.uuid4().hex}{ext}"
    rel_path = f"profiles/{filename}"
    (upload_root / rel_path).write_bytes(content)

    user = user_crud.get_by_id(db, current_user.id)
    profile_crud.update_profile(db, user, profile_image=f"/uploads/{rel_path}")  # type: ignore[arg-type]
    user = user_crud.get_by_id(db, current_user.id)
    return _profile_out(db, user)  # type: ignore[arg-type]
