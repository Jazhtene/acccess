from pydantic import BaseModel


class MessageResponse(BaseModel):
    message: str


class RejectRequest(BaseModel):
    status: str = "Rejected"
    rejection_reason: str | None = None
