from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.archive import Archive


def list_archives(db: Session) -> list[Archive]:
    return list(db.scalars(select(Archive).order_by(Archive.archived_at.desc())))


def create(db: Session, data: dict, archived_by: int) -> Archive:
    row = Archive(**data, archived_by=archived_by)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
