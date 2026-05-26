"""
SQLAlchemy engine and session setup.

Connects to PostgreSQL database `access` (see .env / app.config.Settings).
All ORM models inherit from Base; run create_tables.py to create tables.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

# postgresql+psycopg://postgres:***@localhost:5432/access
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    echo=False,  # set True to log SQL during development
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""


def get_db():
    """FastAPI dependency: yields a database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
