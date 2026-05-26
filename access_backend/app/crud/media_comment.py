from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.media_comment import MediaComment


def list_for_media(db: Session, media_id: int) -> list[MediaComment]:
    return list(
        db.scalars(
            select(MediaComment)
            .options(joinedload(MediaComment.user))
            .where(MediaComment.media_id == media_id)
            .order_by(MediaComment.created_at.asc())
        )
    )


def create(db: Session, data: dict) -> MediaComment:
    row = MediaComment(**data)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
