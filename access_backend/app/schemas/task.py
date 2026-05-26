from datetime import date, datetime

from pydantic import BaseModel


class TaskCreate(BaseModel):
    title: str
    description: str | None = None
    assigned_to: int | None = None
    event_id: int | None = None
    due_date: date | None = None
    status: str = "Open"


class TaskResponse(BaseModel):
    task_id: int
    title: str
    description: str | None
    assigned_to: int | None
    event_id: int | None
    status: str
    due_date: date | None
    created_by: int | None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}
