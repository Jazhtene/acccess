"""Event documentation requests submitted by organizations or members."""

from datetime import date

from sqlalchemy import Date, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin


class DocumentationRequest(TimestampMixin, Base):
    __tablename__ = "documentation_requests"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    requestor_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    event_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    venue: Mapped[str | None] = mapped_column(String(200))
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="pending", index=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text)

    requestor = relationship("User", back_populates="documentation_requests", foreign_keys=[requestor_id])
    assignments = relationship(
        "RequestAssignment", back_populates="request", cascade="all, delete-orphan"
    )
    calendar_events = relationship(
        "EventCalendar", back_populates="request", cascade="all, delete-orphan"
    )
    media_files = relationship("MediaFile", back_populates="request", cascade="all, delete-orphan")
    feedbacks = relationship("Feedback", back_populates="request", cascade="all, delete-orphan")
