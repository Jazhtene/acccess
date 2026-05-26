"""Organization Facebook connection (flutter_facebook_auth metadata)."""

from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class FacebookSetting(Base):
    """Single-row style config — latest connection wins (id=1)."""

    __tablename__ = "facebook_settings"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    facebook_user_id: Mapped[str | None] = mapped_column(String(100), index=True)
    facebook_user_name: Mapped[str | None] = mapped_column(String(200))
    facebook_email: Mapped[str | None] = mapped_column(String(255))
    page_id: Mapped[str | None] = mapped_column(String(100))
    page_name: Mapped[str | None] = mapped_column(String(200))
    is_connected: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    auto_share_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    connected_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), index=True
    )
    access_token_hint: Mapped[str | None] = mapped_column(String(50))
    notes: Mapped[str | None] = mapped_column(Text)
    connected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    connector = relationship("User", foreign_keys=[connected_by])
