"""Photography skill tiers used for member rankings and badges."""

from sqlalchemy import Float, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class SkillLevel(Base):
    __tablename__ = "skill_levels"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    level_name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    min_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    max_score: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)

    users = relationship("User", back_populates="skill_level")
