"""Admin member removal (soft delete)."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_admin
from app.crud import user as user_crud
from app.database import get_db
from app.models.audit_log import AuditLog
from app.models.enums import RoleName
from app.models.user import User
from app.schemas.admin_member import MemberRemoveBody
from app.schemas.common import MessageResponse

router = APIRouter(prefix="/admin/members", tags=["Admin Members"])


@router.patch("/{user_id}/remove", response_model=MessageResponse)
def remove_member(
    user_id: int,
    body: MemberRemoveBody | None = None,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = user_crud.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Member not found")
    if not user.role or user.role.role_name != RoleName.MEMBER:
        raise HTTPException(
            status_code=400,
            detail="Only Member accounts can be removed from Member Management",
        )
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="You cannot remove your own admin account")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Member is already removed")

    reason = (body.removal_reason if body else None) or None
    user_crud.remove_member(db, user, removed_by=admin.id, removal_reason=reason)
    db.add(
        AuditLog(
            user_id=admin.id,
            action="member_removed",
            description=f"Removed member {user_id} ({user.email})"
            + (f": {reason}" if reason else ""),
        )
    )
    db.commit()
    return MessageResponse(message="Member removed successfully")
