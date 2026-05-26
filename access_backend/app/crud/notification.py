from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session, joinedload

from app.models.notification import Notification


def list_for_user(db: Session, user_id: int, *, limit: int = 100) -> list[Notification]:
    return list(
        db.scalars(
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .limit(limit)
        )
    )


def get(db: Session, notification_id: int, user_id: int) -> Notification | None:
    return db.scalar(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        )
    )


def mark_read(db: Session, notification: Notification) -> Notification:
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification


def mark_all_read(db: Session, user_id: int) -> int:
    result = db.execute(
        update(Notification)
        .where(Notification.user_id == user_id, Notification.is_read.is_(False))
        .values(is_read=True)
    )
    db.commit()
    return result.rowcount


def delete_read_for_user(db: Session, user_id: int) -> int:
    result = db.execute(
        delete(Notification).where(
            Notification.user_id == user_id,
            Notification.is_read.is_(True),
        )
    )
    db.commit()
    return result.rowcount


def create(
    db: Session,
    user_id: int,
    title: str,
    message: str,
    *,
    category: str = "system_alert",
    priority: str = "normal",
    action_type: str | None = None,
    action_ref_id: int | None = None,
) -> Notification:
    row = Notification(
        user_id=user_id,
        title=title,
        message=message,
        category=category,
        priority=priority,
        action_type=action_type,
        action_ref_id=action_ref_id,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_all(db: Session, limit: int = 100) -> list[Notification]:
    return list(
        db.scalars(
            select(Notification)
            .options(joinedload(Notification.user))
            .order_by(Notification.created_at.desc())
            .limit(limit)
        )
    )


def broadcast(
    db: Session,
    user_ids: list[int],
    title: str,
    message: str,
    *,
    category: str = "system_alert",
    priority: str = "normal",
    action_type: str | None = None,
    action_ref_id: int | None = None,
) -> int:
    for uid in user_ids:
        db.add(
            Notification(
                user_id=uid,
                title=title,
                message=message,
                category=category,
                priority=priority,
                action_type=action_type,
                action_ref_id=action_ref_id,
            )
        )
    db.commit()
    return len(user_ids)


def notification_to_dict(n: Notification) -> dict:
    return {
        "id": n.id,
        "user_id": n.user_id,
        "title": n.title,
        "message": n.message,
        "is_read": n.is_read,
        "category": n.category,
        "priority": n.priority,
        "action_type": n.action_type,
        "action_ref_id": n.action_ref_id,
        "created_at": n.created_at.isoformat() if n.created_at else None,
    }
