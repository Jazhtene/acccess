from datetime import datetime

from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    user_id: int
    name: str
    email: str
    role: str
    status: str
    skill_level: str | None = None
    good_evaluations: int = 0
    avg_score: float = 0.0
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class UserStatusUpdate(BaseModel):
    status: str  # approved | rejected | pending


class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str = "Member"
