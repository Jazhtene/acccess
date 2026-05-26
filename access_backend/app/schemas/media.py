from datetime import datetime

from pydantic import BaseModel


class MediaResponse(BaseModel):
    media_id: int
    user_id: int
    title: str
    category: str
    file_url: str | None
    media_type: str
    ai_detected: bool
    quality_score: float | None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class MediaCreateMeta(BaseModel):
    title: str
    category: str = "Events"
    description: str | None = None
