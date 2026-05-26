"""In-app alerts for admins and members."""

from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin


class Notification(TimestampMixin, Base):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)
    category: Mapped[str] = mapped_column(String(40), nullable=False, default="system_alert", index=True)
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="normal", index=True)
    action_type: Mapped[str | None] = mapped_column(String(40))
    action_ref_id: Mapped[int | None] = mapped_column(Integer)

    user = relationship("User", back_populates="notifications")
