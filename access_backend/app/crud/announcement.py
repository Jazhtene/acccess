from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.announcement import Announcement


def create(db: Session, *, title: str, content: str, posted_by: int) -> Announcement:
    row = Announcement(title=title, content=content, posted_by=posted_by)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_all(db: Session, limit: int = 50) -> list[Announcement]:
    return list(
        db.scalars(
            select(Announcement)
            .options(joinedload(Announcement.poster))
            .order_by(Announcement.created_at.desc())
            .limit(limit)
        )
    )
