from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.facebook import FacebookIntegration, FacebookShareLog


def list_integrations(db: Session) -> list[FacebookIntegration]:
    return list(db.scalars(select(FacebookIntegration).order_by(FacebookIntegration.created_at.desc())))


def create_integration(db: Session, data: dict, created_by: int) -> FacebookIntegration:
    row = FacebookIntegration(**data, created_by=created_by)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def log_share(db: Session, user_id: int, media_id: int | None, post_url: str | None, status: str) -> FacebookShareLog:
    row = FacebookShareLog(user_id=user_id, media_id=media_id, post_url=post_url, status=status)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
