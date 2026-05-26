from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.audit_log import AuditLog


def create(db: Session, *, user_id: int | None, action: str, description: str | None = None) -> AuditLog:
    row = AuditLog(user_id=user_id, action=action, description=description)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_recent(db: Session, limit: int = 50) -> list[AuditLog]:
    return list(
        db.scalars(
            select(AuditLog)
            .options(joinedload(AuditLog.user))
            .order_by(AuditLog.created_at.desc())
            .limit(limit)
        )
    )
