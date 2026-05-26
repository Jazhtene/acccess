"""Calendar entries linked to approved documentation requests."""

from datetime import date, time

from sqlalchemy import Date, ForeignKey, String, Text, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin


class EventCalendar(TimestampMixin, Base):
    __tablename__ = "event_calendar"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    request_id: Mapped[int | None] = mapped_column(
        ForeignKey("documentation_requests.id", ondelete="SET NULL"), nullable=True, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    start_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    end_date: Mapped[date | None] = mapped_column(Date)
    start_time: Mapped[time | None] = mapped_column(Time)
    end_time: Mapped[time | None] = mapped_column(Time)
    venue: Mapped[str | None] = mapped_column(String(200))
    status: Mapped[str] = mapped_column(String(40), nullable=False, default="upcoming", index=True)
    assigned_member_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    admin_remarks: Mapped[str | None] = mapped_column(Text)

    request = relationship("DocumentationRequest", back_populates="calendar_events")
    assigned_member = relationship("User", foreign_keys=[assigned_member_id])

