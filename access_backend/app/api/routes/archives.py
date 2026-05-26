"""Repository search — filtered media_files."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import media as media_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import MediaOut

router = APIRouter(prefix="/repository", tags=["Repository"])


@router.get("", response_model=list[MediaOut])
def search_repository(
    search: str | None = None,
    file_type: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_approved),
):
    from app.api.routes.media import _media_out

    items = media_crud.list_media(db, file_type=file_type, search=search)
    return [_media_out(m) for m in items]
