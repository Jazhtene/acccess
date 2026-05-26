"""Archived media removed from active galleries."""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Archive(Base):
    __tablename__ = "archives"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    media_id: Mapped[int] = mapped_column(
        ForeignKey("media_files.id", ondelete="CASCADE"), nullable=False, index=True
    )
    archived_by: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    archived_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    media = relationship("MediaFile", back_populates="archives")
    archiver = relationship("User", back_populates="archives_created")
