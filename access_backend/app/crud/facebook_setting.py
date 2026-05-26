from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.config import settings
from app.models.facebook_setting import FacebookSetting


def _default_page_id() -> str | None:
    pid = (settings.facebook_page_id or "").strip()
    return pid or None


def get_settings(db: Session) -> FacebookSetting:
    row = db.scalar(
        select(FacebookSetting)
        .options(joinedload(FacebookSetting.connector))
        .order_by(FacebookSetting.id.desc())
        .limit(1)
    )
    if row:
        if not row.page_id and _default_page_id():
            row.page_id = _default_page_id()
            db.commit()
            db.refresh(row)
        return row
    row = FacebookSetting(
        is_connected=False,
        auto_share_enabled=False,
        page_id=_default_page_id(),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def connect(
    db: Session,
    *,
    connected_by: int,
    facebook_user_id: str,
    facebook_user_name: str,
    facebook_email: str | None = None,
    page_id: str | None = None,
    page_name: str | None = None,
    token_hint: str | None = None,
) -> FacebookSetting:
    row = get_settings(db)
    row.is_connected = True
    row.facebook_user_id = facebook_user_id
    row.facebook_user_name = facebook_user_name
    row.facebook_email = facebook_email
    row.page_id = page_id
    row.page_name = page_name
    row.connected_by = connected_by
    row.access_token_hint = token_hint
    row.connected_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(row)
    return row


def disconnect(db: Session) -> FacebookSetting:
    row = get_settings(db)
    row.is_connected = False
    row.facebook_user_id = None
    row.facebook_user_name = None
    row.facebook_email = None
    row.page_id = None
    row.page_name = None
    row.access_token_hint = None
    row.connected_at = None
    db.commit()
    db.refresh(row)
    return row


def update_preferences(
    db: Session,
    *,
    auto_share_enabled: bool | None = None,
    page_id: str | None = None,
    page_name: str | None = None,
    notes: str | None = None,
) -> FacebookSetting:
    row = get_settings(db)
    if auto_share_enabled is not None:
        row.auto_share_enabled = auto_share_enabled
    if page_id is not None:
        row.page_id = page_id
    if page_name is not None:
        row.page_name = page_name
    if notes is not None:
        row.notes = notes
    db.commit()
    db.refresh(row)
    return row
