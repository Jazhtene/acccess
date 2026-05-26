from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.api.deps import require_admin, require_approved
from app.crud import rankings_admin
from app.crud import user as user_crud
from app.database import get_db
from app.models.user import User
from app.schemas.common import MessageResponse

router = APIRouter(prefix="/rankings", tags=["Rankings & Skills"])


class RankingRemarksUpdate(BaseModel):
    admin_remarks: str | None = Field(None, max_length=2000)


@router.get("")
def get_rankings(db: Session = Depends(get_db), _: User = Depends(require_approved)):
    """Skill classification and member rankings."""
    try:
        return user_crud.rankings(db)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "success": False,
                "message": "Unable to load member rankings",
                "details": str(exc),
            },
        ) from exc


@router.get("/summary")
def get_rankings_summary(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    try:
        rows = rankings_admin.list_rankings(db)
        return rankings_admin.rankings_summary(rows)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "success": False,
                "message": "Unable to load rankings summary",
                "details": str(exc),
            },
        ) from exc


@router.patch("/{user_id}/remarks", response_model=MessageResponse)
def update_ranking_remarks(
    user_id: int,
    body: RankingRemarksUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    rankings_admin.update_admin_remarks(db, user_id, body.admin_remarks)
    return MessageResponse(message="Ranking remarks updated")
