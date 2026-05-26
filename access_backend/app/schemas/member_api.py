"""Pydantic schemas for member-facing API responses."""

from datetime import date, datetime

from pydantic import BaseModel, EmailStr, Field


class AssignmentOut(BaseModel):
    id: int
    request_id: int
    member_id: int
    task_role: str
    status: str
    request_title: str
    request_description: str | None = None
    event_date: date
    venue: str | None = None
    request_status: str

    model_config = {"from_attributes": True}


class EventOut(BaseModel):
    id: int
    request_id: int | None = None
    title: str
    start_date: date
    end_date: date | None = None
    venue: str | None = None

    model_config = {"from_attributes": True}


class NotificationOut(BaseModel):
    id: int
    title: str
    message: str
    is_read: bool
    category: str = "system_alert"
    priority: str = "normal"
    action_type: str | None = None
    action_ref_id: int | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class MediaOut(BaseModel):
    id: int
    uploaded_by: int | None
    request_id: int
    file_name: str
    file_type: str
    file_url: str
    uploaded_at: datetime
    overall_score: float | None = None
    ai_detected: bool = False
    ai_probability: float | None = None
    feedback: str | None = None


class EvaluationOut(BaseModel):
    id: int
    media_id: int
    file_name: str
    file_url: str
    sharpness_score: float
    brightness_score: float
    contrast_score: float
    blur_score: float
    noise_score: float
    overall_score: float
    feedback: str | None
    evaluated_at: datetime
    ai_probability: float | None = None
    detection_result: str | None = None
    quality_level: str | None = None
    recommendation: str | None = None
    criteria_json: str | None = None


class FeedbackCreate(BaseModel):
    request_id: int
    rating: int = Field(ge=1, le=5)
    comment: str | None = None


class FeedbackOut(BaseModel):
    id: int
    request_id: int
    user_id: int
    rating: int
    comment: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class CommentCreate(BaseModel):
    comment: str = Field(min_length=1, max_length=2000)


class CommentOut(BaseModel):
    id: int
    media_id: int
    user_id: int
    user_name: str
    comment: str
    created_at: datetime

    model_config = {"from_attributes": True}


class FacebookShareCreate(BaseModel):
    media_id: int
    message: str | None = Field(default=None, max_length=5000)


class FacebookPostOut(BaseModel):
    id: int
    media_id: int
    message: str | None = None
    facebook_post_id: str | None = None
    status: str
    error_message: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ProfileOut(BaseModel):
    id: int
    name: str
    email: str
    role: str
    status: str
    student_id: str | None = None
    contact_number: str | None = None
    adviser_name: str | None = None
    profile_image: str | None = None
    skill_level: str | None = None
    total_points: int = 0
    rank_position: int | None = None
    uploads_count: int = 0
    assignments_completed: int = 0


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    email: EmailStr | None = None
    contact_number: str | None = Field(default=None, min_length=1, max_length=40)
    profile_image: str | None = None
    new_password: str | None = Field(default=None, min_length=6, max_length=128)


class ParticipationOut(BaseModel):
    assignments_total: int
    assignments_completed: int
    uploads_count: int
    evaluations_count: int
    average_score: float
    total_points: int
    rank_position: int | None = None


class AssignmentStatusUpdate(BaseModel):
    status: str = Field(min_length=1, max_length=30)
