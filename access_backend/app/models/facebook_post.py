"""Facebook share log — every post attempt (success or failure)."""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class FacebookPost(Base):
    __tablename__ = "facebook_posts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    media_id: Mapped[int] = mapped_column(
        ForeignKey("media_files.id", ondelete="CASCADE"), nullable=False, index=True
    )
    message: Mapped[str | None] = mapped_column(Text)
    facebook_post_id: Mapped[str | None] = mapped_column(String(100), index=True)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="pending", index=True)
    error_message: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    media = relationship("MediaFile", back_populates="facebook_posts")
