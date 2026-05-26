"""Login attempts for security monitoring."""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class LoginHistory(Base):
    __tablename__ = "login_history"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    login_time: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
    ip_address: Mapped[str | None] = mapped_column(String(45))
    device_info: Mapped[str | None] = mapped_column(String(255))

    user = relationship("User", back_populates="login_history")
