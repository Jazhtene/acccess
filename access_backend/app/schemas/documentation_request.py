from datetime import date, datetime

from pydantic import BaseModel, Field


class DocumentationRequestCreate(BaseModel):
    type: str
    event_name: str | None = None
    event_date: date | None = None
    venue: str | None = None
    details: str | None = None


class DocumentationRequestUpdate(BaseModel):
    status: str | None = None
    rejection_reason: str | None = None


class DocumentationRequestResponse(BaseModel):
    request_id: int
    requester_id: int
    requester_name: str | None
    type: str
    event_name: str | None
    event_date: date | None
    venue: str | None
    details: str | None
    status: str
    rejection_reason: str | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}
