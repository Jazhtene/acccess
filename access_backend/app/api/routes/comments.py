from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import media as media_crud
from app.crud import media_comment as comment_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import CommentCreate, CommentOut

router = APIRouter(prefix="/media", tags=["Media Comments"])


@router.get("/{media_id}/comments", response_model=list[CommentOut])
def list_comments(
    media_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_approved),
):
    if not media_crud.get(db, media_id):
        raise HTTPException(status_code=404, detail="Media not found")
    rows = comment_crud.list_for_media(db, media_id)
    return [
        CommentOut(
            id=r.id,
            media_id=r.media_id,
            user_id=r.user_id,
            user_name=r.user.fullname,
            comment=r.comment,
            created_at=r.created_at,
        )
        for r in rows
    ]


@router.post("/{media_id}/comments", response_model=CommentOut)
def add_comment(
    media_id: int,
    body: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    if not media_crud.get(db, media_id):
        raise HTTPException(status_code=404, detail="Media not found")
    row = comment_crud.create(
        db,
        {"media_id": media_id, "user_id": current_user.id, "comment": body.comment},
    )
    row = comment_crud.list_for_media(db, media_id)[-1]
    return CommentOut(
        id=row.id,
        media_id=row.media_id,
        user_id=row.user_id,
        user_name=row.user.fullname,
        comment=row.comment,
        created_at=row.created_at,
    )
