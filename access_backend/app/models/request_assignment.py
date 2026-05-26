"""Members assigned to cover a documentation request."""

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class RequestAssignment(Base):
    __tablename__ = "request_assignments"
    __table_args__ = (UniqueConstraint("request_id", "member_id", name="uq_request_member"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    request_id: Mapped[int] = mapped_column(
        ForeignKey("documentation_requests.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    assigned_by: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    task_role: Mapped[str] = mapped_column(String(50), nullable=False, default="photographer")
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="assigned", index=True)

    request = relationship("DocumentationRequest", back_populates="assignments")
    member = relationship("User", back_populates="request_assignments_as_member", foreign_keys=[member_id])
    assigner = relationship("User", back_populates="request_assignments_assigned", foreign_keys=[assigned_by])
