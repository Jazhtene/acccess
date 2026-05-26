"""Periodic dashboard snapshots for the admin web app."""

from datetime import datetime

from sqlalchemy import DateTime, Integer, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AnalyticsReport(Base):
    __tablename__ = "analytics_reports"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    total_requests: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_media: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_members: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
