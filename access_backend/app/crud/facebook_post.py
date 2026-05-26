from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.facebook_post import FacebookPost


def list_for_media(db: Session, media_id: int, *, limit: int = 20) -> list[FacebookPost]:
    return list(
        db.scalars(
            select(FacebookPost)
            .where(FacebookPost.media_id == media_id)
            .order_by(FacebookPost.created_at.desc())
            .limit(limit)
        )
    )


def list_recent(db: Session, *, limit: int = 50) -> list[FacebookPost]:
    return list(
        db.scalars(
            select(FacebookPost).order_by(FacebookPost.created_at.desc()).limit(limit)
        )
    )


def create_attempt(db: Session, *, media_id: int, message: str | None) -> FacebookPost:
    row = FacebookPost(
        media_id=media_id,
        message=message,
        status="pending",
        facebook_post_id=None,
        error_message=None,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def mark_success(db: Session, row: FacebookPost, facebook_post_id: str) -> FacebookPost:
    row.status = "success"
    row.facebook_post_id = facebook_post_id
    row.error_message = None
    db.commit()
    db.refresh(row)
    return row


def mark_opened_in_browser(db: Session, row: FacebookPost) -> FacebookPost:
    row.status = "opened_browser"
    row.facebook_post_id = None
    row.error_message = None
    db.commit()
    db.refresh(row)
    return row


def mark_failed(db: Session, row: FacebookPost, error_message: str) -> FacebookPost:
    row.status = "failed"
    row.error_message = error_message[:2000]
    db.commit()
    db.refresh(row)
    return row
