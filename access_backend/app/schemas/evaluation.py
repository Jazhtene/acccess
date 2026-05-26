from datetime import datetime

from pydantic import BaseModel, Field


class EvaluationCreate(BaseModel):
    title: str = "Photo Submission"
    score: float = Field(ge=0, le=1)
    composition: str | None = None
    lighting: str | None = None
    feedback: str | None = None
    ai_detected: bool = False
    media_id: int | None = None
    blur_score: float | None = None
    lighting_score: float | None = None
    resolution_score: float | None = None
    composition_score: float | None = None
    ai_confidence: float | None = None
    ai_method: str | None = None
    risk_level: str | None = None
    skill_badge: str | None = None
    pending_admin_review: bool = False


class EvaluationResponse(BaseModel):
    evaluation_id: int
    user_id: int
    media_id: int | None
    title: str
    score: float
    composition: str | None
    lighting: str | None
    feedback: str | None
    ai_detected: bool
    ai_confidence: float | None
    risk_level: str | None
    skill_badge: str | None
    pending_admin_review: bool
    member_name: str | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}
