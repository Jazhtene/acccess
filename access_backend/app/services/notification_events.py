"""Create notifications when platform events occur."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.crud import notification as notification_crud
from app.models.enums import RoleName, UserStatus
from app.models.role import Role
from app.models.user import User


def _admin_user_ids(db: Session) -> list[int]:
    return list(
        db.scalars(
            select(User.id)
            .join(Role, User.role_id == Role.id)
            .where(User.status == UserStatus.APPROVED, Role.role_name == RoleName.ADMIN)
        )
    )


def notify_user(
    db: Session,
    user_id: int,
    *,
    title: str,
    message: str,
    category: str = "system_alert",
    priority: str = "normal",
    action_type: str | None = None,
    action_ref_id: int | None = None,
) -> None:
    notification_crud.create(
        db,
        user_id,
        title,
        message,
        category=category,
        priority=priority,
        action_type=action_type,
        action_ref_id=action_ref_id,
    )


def notify_admins(
    db: Session,
    *,
    title: str,
    message: str,
    category: str = "system_alert",
    priority: str = "normal",
    action_type: str | None = None,
    action_ref_id: int | None = None,
) -> int:
    ids = _admin_user_ids(db)
    if not ids:
        return 0
    return notification_crud.broadcast(
        db,
        ids,
        title,
        message,
        category=category,
        priority=priority,
        action_type=action_type,
        action_ref_id=action_ref_id,
    )


def notify_documentation_request_submitted(db: Session, request_id: int, title: str, requester: str) -> None:
    notify_admins(
        db,
        title="New documentation request",
        message=f'{requester} submitted "{title}" for review.',
        category="documentation_request",
        priority="high",
        action_type="view_request",
        action_ref_id=request_id,
    )


def notify_documentation_request_status(
    db: Session,
    user_id: int,
    request_id: int,
    title: str,
    status: str,
) -> None:
    st = status.strip().lower()
    if st == "approved":
        msg = f'Your documentation request "{title}" was approved.'
        priority = "high"
    elif st == "rejected":
        msg = f'Your documentation request "{title}" was rejected. Check admin remarks.'
        priority = "high"
    else:
        msg = f'Your documentation request "{title}" status is now {status}.'
        priority = "normal"
    notify_user(
        db,
        user_id,
        title="Documentation request updated",
        message=msg,
        category="documentation_request",
        priority=priority,
        action_type="view_request",
        action_ref_id=request_id,
    )


def notify_task_assigned(db: Session, member_id: int, assignment_id: int, task_title: str, role: str) -> None:
    notify_user(
        db,
        member_id,
        title="Task assigned",
        message=f'You were assigned as {role} for "{task_title}".',
        category="task_assignment",
        priority="high",
        action_type="view_task",
        action_ref_id=assignment_id,
    )
    notify_admins(
        db,
        title="Member assigned to event",
        message=f'Member assigned as {role} for "{task_title}".',
        category="task_assignment",
        priority="normal",
        action_type="view_task",
        action_ref_id=assignment_id,
    )


def notify_event_member_assigned(
    db: Session,
    *,
    event_id: int,
    event_title: str,
    member_id: int,
    event_date: str | None = None,
) -> None:
    when = f" on {event_date}" if event_date else ""
    notify_user(
        db,
        member_id,
        title="Event assignment",
        message=f'You were assigned to "{event_title}"{when}.',
        category="task_assignment",
        priority="high",
        action_type="view_task",
        action_ref_id=event_id,
    )
    notify_admins(
        db,
        title="Member assigned to event",
        message=f'A member was assigned to "{event_title}"{when}.',
        category="task_assignment",
        priority="normal",
        action_type="view_task",
        action_ref_id=event_id,
    )


def notify_media_uploaded(db: Session, media_id: int, file_name: str, uploader: str) -> None:
    notify_admins(
        db,
        title="New media uploaded",
        message=f'{uploader} uploaded "{file_name}" for review.',
        category="media_evaluation",
        priority="normal",
        action_type="view_result",
        action_ref_id=media_id,
    )


def notify_media_evaluated(db: Session, user_id: int, media_id: int, file_name: str, score_pct: int) -> None:
    notify_user(
        db,
        user_id,
        title="Media evaluation completed",
        message=f'Your upload "{file_name}" scored {score_pct}%.',
        category="media_evaluation",
        priority="normal",
        action_type="view_result",
        action_ref_id=media_id,
    )


def notify_ai_detection_alert(
    db: Session,
    media_id: int,
    file_name: str,
    uploader: str,
    *,
    member_id: int | None = None,
) -> None:
    notify_admins(
        db,
        title="AI detection alert",
        message=f'Suspicious or AI-generated content detected on "{file_name}" by {uploader}.',
        category="ai_detection",
        priority="high",
        action_type="review_media",
        action_ref_id=media_id,
    )
    if member_id:
        notify_user(
            db,
            member_id,
            title="Media under AI review",
            message=f'Your upload "{file_name}" is under AI review. Please wait for admin verification.',
            category="ai_detection",
            priority="normal",
            action_type="view_result",
            action_ref_id=media_id,
        )


def notify_feedback_submitted(db: Session, feedback_id: int, event_title: str, rating: int, from_user: str) -> None:
    notify_admins(
        db,
        title="New feedback submitted",
        message=f'{from_user} rated "{event_title}" {rating}/5.',
        category="feedback",
        priority="normal",
        action_type="view_feedback",
        action_ref_id=feedback_id,
    )
