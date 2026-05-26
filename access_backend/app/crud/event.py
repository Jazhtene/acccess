from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.event import Event


def list_events(db: Session) -> list[Event]:
    return list(db.scalars(select(Event).order_by(Event.event_date.asc())))


def create(db: Session, data: dict, created_by: int | None) -> Event:
    row = Event(**data, created_by=created_by)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
