"""Threaded discussion on media items."""

from sqlalchemy import ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin


class MediaComment(TimestampMixin, Base):
    __tablename__ = "media_comments"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    media_id: Mapped[int] = mapped_column(
        ForeignKey("media_files.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    comment: Mapped[str] = mapped_column(Text, nullable=False)

    media = relationship("MediaFile", back_populates="comments")
    user = relationship("User", back_populates="media_comments")
