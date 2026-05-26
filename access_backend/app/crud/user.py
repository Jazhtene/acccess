from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.core.security import hash_password, verify_password
from app.models.enums import RoleName, UserStatus
from app.models.role import Role
from app.models.skill_level import SkillLevel
from app.models.user import User


def get_by_email(db: Session, email: str) -> User | None:
    return db.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.skill_level))
        .where(User.email == email.lower())
    )


def get_by_id(db: Session, user_id: int) -> User | None:
    return db.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.skill_level))
        .where(User.id == user_id)
    )


def _role_id_for_name(db: Session, role: str) -> int:
    mapping = {
        "admin": RoleName.ADMIN,
        "member": RoleName.MEMBER,
        "organization": RoleName.ORGANIZATION,
    }
    role_name = mapping.get(role.strip().lower(), RoleName.MEMBER)
    row = db.scalar(select(Role).where(Role.role_name == role_name))
    if not row:
        raise ValueError(f"Role not found: {role_name}")
    return row.id


def _skill_level_id_for_name(db: Session, skill_name: str | None) -> int | None:
    if not skill_name or not skill_name.strip():
        return None
    row = db.scalar(
        select(SkillLevel).where(
            func.lower(SkillLevel.level_name) == skill_name.strip().lower()
        )
    )
    return row.id if row else None


def create_user(
    db: Session,
    name: str,
    email: str,
    password: str,
    role: str,
    *,
    status: str | None = None,
    student_id: str | None = None,
    contact_number: str | None = None,
    adviser_name: str | None = None,
    skill_level: str | None = None,
) -> User:
    role_name = role.strip().lower()
    is_admin = role_name == "admin"
    novice = db.scalar(select(SkillLevel).where(SkillLevel.level_name == "Novice"))
    skill_id = _skill_level_id_for_name(db, skill_level) or (novice.id if novice else None)

    if status is None:
        account_status = UserStatus.APPROVED if is_admin else UserStatus.PENDING
    else:
        account_status = status.strip().lower()

    user = User(
        fullname=name.strip(),
        email=email.lower(),
        password=hash_password(password),
        role_id=_role_id_for_name(db, role),
        skill_level_id=skill_id,
        status=account_status,
        student_id=student_id.strip() if student_id and student_id.strip() else None,
        contact_number=contact_number.strip() if contact_number and contact_number.strip() else None,
        adviser_name=adviser_name.strip() if adviser_name and adviser_name.strip() else None,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return get_by_id(db, user.id)  # type: ignore[arg-type]


def authenticate(db: Session, email: str, password: str) -> User | None:
    user = get_by_email(db, email)
    if not user or not verify_password(password, user.password):
        return None
    if not user.is_active:
        return None
    return user


def remove_member(
    db: Session,
    user: User,
    *,
    removed_by: int,
    removal_reason: str | None = None,
) -> User:
    """Soft-delete a member account — blocks login and hides from active lists."""
    from app.crud import session as session_crud

    user.is_active = False
    user.removed_at = datetime.now(timezone.utc)
    user.removed_by = removed_by
    user.removal_reason = (removal_reason or "").strip() or None
    db.commit()
    session_crud.revoke_sessions_for_user(db, user.id)
    db.refresh(user)
    return user


def list_users(db: Session) -> list[User]:
    return list(
        db.scalars(
            select(User).options(joinedload(User.role)).order_by(User.created_at.desc())
        )
    )


def update_status(
    db: Session,
    user: User,
    status: str,
    *,
    rejection_reason: str | None = None,
    approved_by: int | None = None,
) -> User:
    normalized = status.strip().lower()
    user.status = normalized
    if normalized == UserStatus.REJECTED:
        user.rejection_reason = (rejection_reason or "").strip() or None
        user.approved_by = None
        user.approved_at = None
    elif normalized == UserStatus.APPROVED:
        user.rejection_reason = None
        user.approved_by = approved_by
        user.approved_at = datetime.now(timezone.utc)
    else:
        user.rejection_reason = None
        user.approved_by = None
        user.approved_at = None
    db.commit()
    db.refresh(user)
    return user


def update_skill_from_evaluation(db: Session, user: User, score: float) -> None:
    """Assign skill_level_id from overall_score using skill_levels ranges."""
    levels = db.scalars(select(SkillLevel).order_by(SkillLevel.min_score.asc())).all()
    for level in levels:
        if level.min_score <= score <= level.max_score:
            user.skill_level_id = level.id
            break
    db.commit()


def rankings(db: Session) -> list[dict]:
    from app.crud import rankings_admin

    return rankings_admin.list_rankings(db)
