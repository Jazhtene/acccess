from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_admin
from app.crud import admin_members as admin_members_crud
from app.crud import user as user_crud
from app.database import get_db
from app.models.audit_log import AuditLog
from app.models.user import User
from app.schemas.admin_member import AdminMemberResponse, UserRoleUpdate, UserStatusUpdate
from app.schemas.common import MessageResponse
from app.schemas.user import UserCreate, UserResponse

router = APIRouter(tags=["Users"])


@router.post("/users", response_model=UserResponse)
def create_user(
    body: UserCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Admin: create a new user account."""
    if user_crud.get_by_email(db, body.email):
        raise HTTPException(status_code=409, detail="Email already registered")
    user = user_crud.create_user(
        db,
        body.name,
        body.email,
        body.password,
        body.role,
        status="approved",
    )
    ranking = user.member_ranking
    return UserResponse(
        user_id=user.id,
        name=user.fullname,
        email=user.email,
        role=user.role.role_name,
        status=user.status,
        skill_level=user.skill_level.level_name if user.skill_level else None,
        good_evaluations=ranking.total_points if ranking else 0,
        avg_score=0.0,
        created_at=user.created_at,
    )


@router.get("/users", response_model=list[AdminMemberResponse])
def list_users(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return [AdminMemberResponse(**row) for row in admin_members_crud.list_admin_members(db)]


@router.patch("/users/{user_id}/status", response_model=MessageResponse)
def update_user_status(
    user_id: int,
    body: UserStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = user_crud.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    status = body.status.strip().lower()
    if status == "rejected" and not (body.rejection_reason or "").strip():
        raise HTTPException(status_code=400, detail="Rejection reason is required")
    user_crud.update_status(
        db,
        user,
        status,
        rejection_reason=body.rejection_reason,
        approved_by=admin.id if status == "approved" else None,
    )
    if body.rejection_reason:
        db.add(
            AuditLog(
                user_id=admin.id,
                action="member_rejected",
                description=f"User {user_id} rejected: {body.rejection_reason.strip()}",
            )
        )
        db.commit()
    return MessageResponse(message=f"User {status}")


@router.patch("/users/{user_id}/role", response_model=MessageResponse)
def update_user_role(
    user_id: int,
    body: UserRoleUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    user = user_crud.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    try:
        role_id = user_crud._role_id_for_name(db, body.role)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    user.role_id = role_id
    db.commit()
    return MessageResponse(message=f"Role updated to {body.role}")
