from datetime import date, datetime, time

from pydantic import BaseModel


class EventCreate(BaseModel):
    title: str
    event_date: date
    event_time: time | None = None
    location: str | None = None
    description: str | None = None
    tag: str = "COVERAGE"
    color: str = "blue"
    status: str = "OPEN"


class EventResponse(BaseModel):
    event_id: int
    title: str
    event_date: date
    event_time: time | None
    location: str | None
    description: str | None
    tag: str
    color: str
    status: str
    created_by: int | None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}
