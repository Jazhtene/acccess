from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import notification as notification_crud
from app.database import get_db
from app.models.user import User
from app.schemas.common import MessageResponse
from app.schemas.member_api import NotificationOut

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _out(row) -> NotificationOut:
    return NotificationOut(
        id=row.id,
        title=row.title,
        message=row.message,
        is_read=row.is_read,
        category=getattr(row, "category", None) or "system_alert",
        priority=getattr(row, "priority", None) or "normal",
        action_type=getattr(row, "action_type", None),
        action_ref_id=getattr(row, "action_ref_id", None),
        created_at=row.created_at,
    )


@router.get("", response_model=list[NotificationOut])
def list_notifications(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    rows = notification_crud.list_for_user(db, current_user.id)
    return [_out(n) for n in rows]


@router.patch("/{notification_id}/read", response_model=NotificationOut)
def mark_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    row = notification_crud.get(db, notification_id, current_user.id)
    if not row:
        raise HTTPException(status_code=404, detail="Notification not found")
    return _out(notification_crud.mark_read(db, row))


@router.post("/read-all", response_model=MessageResponse)
def mark_all_read(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    count = notification_crud.mark_all_read(db, current_user.id)
    return MessageResponse(message=f"Marked {count} notifications as read")


@router.delete("/read", response_model=MessageResponse)
def clear_read_notifications(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    count = notification_crud.delete_read_for_user(db, current_user.id)
    return MessageResponse(message=f"Cleared {count} read notifications")
