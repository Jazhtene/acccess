from datetime import datetime

from pydantic import BaseModel


class NotificationCreate(BaseModel):
    user_id: int
    title: str | None = None
    message: str


class NotificationResponse(BaseModel):
    notification_id: int
    user_id: int
    title: str | None
    message: str
    is_read: bool
    created_at: datetime | None = None

    model_config = {"from_attributes": True}
