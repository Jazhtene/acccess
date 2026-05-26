"""Member profile and participation records."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import member_profile as profile_crud
from app.crud import member_ranking as ranking_crud
from app.crud import user as user_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import ParticipationOut, ProfileOut, ProfileUpdate

router = APIRouter(prefix="/member", tags=["Member"])


def _profile_out(db: Session, user: User) -> ProfileOut:
    ranking = ranking_crud.get_or_create(db, user.id)
    skill = user.skill_level.level_name if user.skill_level else None
    return ProfileOut(
        id=user.id,
        name=user.fullname,
        email=user.email,
        role=user.role.role_name,
        status=user.status,
        student_id=user.student_id,
        contact_number=user.contact_number,
        adviser_name=user.adviser_name,
        profile_image=user.profile_image,
        skill_level=skill,
        total_points=ranking.total_points,
        rank_position=ranking.rank_position,
        uploads_count=profile_crud.uploads_count(db, user.id),
        assignments_completed=profile_crud.assignments_completed(db, user.id),
    )


@router.get("/profile", response_model=ProfileOut)
def get_profile(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    user = user_crud.get_by_id(db, current_user.id)
    return _profile_out(db, user)  # type: ignore[arg-type]


def apply_profile_update(db: Session, current_user: User, body: ProfileUpdate) -> ProfileOut:
    """Update the logged-in user's profile (shared by /member/profile and /profile)."""
    user = user_crud.get_by_id(db, current_user.id)
    if body.email is not None:
        existing = user_crud.get_by_email(db, str(body.email))
        if existing and existing.id != user.id:
            raise HTTPException(status_code=409, detail="Email already in use")
    profile_crud.update_profile(
        db,
        user,  # type: ignore[arg-type]
        name=body.name,
        email=str(body.email) if body.email is not None else None,
        contact_number=body.contact_number,
        profile_image=body.profile_image,
        new_password=body.new_password,
    )
    user = user_crud.get_by_id(db, current_user.id)
    return _profile_out(db, user)  # type: ignore[arg-type]


@router.patch("/profile", response_model=ProfileOut)
def update_profile(
    body: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    return apply_profile_update(db, current_user, body)


@router.put("/profile", response_model=ProfileOut)
def put_profile(
    body: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    return apply_profile_update(db, current_user, body)


@router.get("/participation", response_model=ParticipationOut)
def participation(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    ranking = ranking_crud.get_or_create(db, current_user.id)
    eval_count, avg = profile_crud.evaluations_stats(db, current_user.id)
    return ParticipationOut(
        assignments_total=profile_crud.assignments_total(db, current_user.id),
        assignments_completed=profile_crud.assignments_completed(db, current_user.id),
        uploads_count=profile_crud.uploads_count(db, current_user.id),
        evaluations_count=eval_count,
        average_score=round(avg, 3),
        total_points=ranking.total_points,
        rank_position=ranking.rank_position,
    )
