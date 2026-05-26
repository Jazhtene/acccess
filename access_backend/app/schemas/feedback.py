from datetime import datetime

from pydantic import BaseModel, Field


class FeedbackCreate(BaseModel):
    event_title: str | None = None
    type: str | None = None
    message: str | None = None
    rating: int | None = Field(default=None, ge=1, le=5)


class FeedbackResponse(BaseModel):
    feedback_id: int
    user_id: int
    event_title: str | None
    type: str | None
    message: str | None
    rating: int | None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}
