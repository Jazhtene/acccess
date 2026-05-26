"""Audit log for admin AI detection review actions."""

from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AiReviewHistory(Base):
    __tablename__ = "ai_review_history"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    ai_detection_id: Mapped[int] = mapped_column(
        ForeignKey("ai_detection_results.id", ondelete="CASCADE"), nullable=False, index=True
    )
    media_id: Mapped[int] = mapped_column(
        ForeignKey("media_files.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    ai_result: Mapped[str | None] = mapped_column(String(50))
    confidence_score: Mapped[float | None] = mapped_column(Float)
    previous_status: Mapped[str | None] = mapped_column(String(40))
    new_status: Mapped[str] = mapped_column(String(40), nullable=False)
    admin_remarks: Mapped[str | None] = mapped_column(Text)
    reviewed_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    ai_detection = relationship("AiDetectionResult", back_populates="review_history")
    reviewer = relationship("User", foreign_keys=[reviewed_by])
