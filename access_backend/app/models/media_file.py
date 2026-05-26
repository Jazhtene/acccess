"""Photos and videos uploaded for a documentation request."""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class MediaFile(Base):
    __tablename__ = "media_files"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    uploaded_by: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    request_id: Mapped[int] = mapped_column(
        ForeignKey("documentation_requests.id", ondelete="CASCADE"), nullable=False, index=True
    )
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    file_url: Mapped[str] = mapped_column(String(500), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )

    uploader = relationship("User", back_populates="uploaded_media")
    request = relationship("DocumentationRequest", back_populates="media_files")
    evaluations = relationship(
        "MediaEvaluation", back_populates="media", cascade="all, delete-orphan"
    )
    ai_detection_results = relationship(
        "AiDetectionResult", back_populates="media", cascade="all, delete-orphan"
    )
    comments = relationship("MediaComment", back_populates="media", cascade="all, delete-orphan")
    archives = relationship("Archive", back_populates="media", cascade="all, delete-orphan")
    facebook_posts = relationship("FacebookPost", back_populates="media", cascade="all, delete-orphan")
