from datetime import date, datetime, time, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.event_calendar import EventCalendar
from app.models.user import User
from app.utils.timestamps import first_timestamp_iso


def list_events(db: Session) -> list[EventCalendar]:
    return list(
        db.scalars(
            select(EventCalendar)
            .options(
                joinedload(EventCalendar.request),
                joinedload(EventCalendar.assigned_member),
            )
            .order_by(EventCalendar.start_date.asc(), EventCalendar.start_time.asc())
        )
    )


def get_event(db: Session, event_id: int) -> EventCalendar | None:
    return db.scalar(
        select(EventCalendar)
        .options(
            joinedload(EventCalendar.request),
            joinedload(EventCalendar.assigned_member),
        )
        .where(EventCalendar.id == event_id)
    )


def create_event(db: Session, data: dict) -> EventCalendar:
    row = EventCalendar(**data)
    db.add(row)
    db.commit()
    db.refresh(row)
    return get_event(db, row.id) or row


def update_event(db: Session, row: EventCalendar, data: dict) -> EventCalendar:
    for key, value in data.items():
        if hasattr(row, key):
            setattr(row, key, value)
    db.commit()
    db.refresh(row)
    return get_event(db, row.id) or row


def delete_event(db: Session, row: EventCalendar) -> None:
    db.delete(row)
    db.commit()


def event_to_json(e: EventCalendar) -> dict:
    member = e.assigned_member
    req = e.request
    return {
        "id": e.id,
        "request_id": e.request_id,
        "documentation_request_id": e.request_id,
        "title": e.title,
        "description": e.description,
        "event_date": e.start_date.isoformat(),
        "start_date": e.start_date.isoformat(),
        "end_date": e.end_date.isoformat() if e.end_date else None,
        "start_time": e.start_time.isoformat() if e.start_time else None,
        "end_time": e.end_time.isoformat() if e.end_time else None,
        "location": e.venue,
        "venue": e.venue,
        "status": e.status,
        "assigned_member_id": e.assigned_member_id,
        "assigned_member_name": member.fullname if member else None,
        "request_status": req.status if req else None,
        "admin_remarks": e.admin_remarks,
        "created_at": first_timestamp_iso(e, "created_at"),
        "updated_at": first_timestamp_iso(e, "updated_at", "created_at"),
    }


def parse_time(value: str | None) -> time | None:
    if not value:
        return None
    for fmt in ("%H:%M:%S", "%H:%M"):
        try:
            return datetime.strptime(value, fmt).time()
        except ValueError:
            continue
    return None


def parse_date(value: str | None) -> date | None:
    if not value:
        return None
    return date.fromisoformat(value[:10])
