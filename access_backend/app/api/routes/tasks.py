"""Assigned tasks (request_assignments) for members."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import assignment as assignment_crud
from app.database import get_db
from app.models.enums import RoleName
from app.models.user import User
from app.schemas.member_api import AssignmentOut, AssignmentStatusUpdate

router = APIRouter(prefix="/tasks", tags=["Tasks"])


def _to_out(row) -> AssignmentOut:
    req = row.request
    return AssignmentOut(
        id=row.id,
        request_id=row.request_id,
        member_id=row.member_id,
        task_role=row.task_role,
        status=row.status,
        request_title=req.title,
        request_description=req.description,
        event_date=req.event_date,
        venue=req.venue,
        request_status=req.status,
    )


@router.get("", response_model=list[AssignmentOut])
def list_tasks(db: Session = Depends(get_db), current_user: User = Depends(require_approved)):
    if current_user.role.role_name == RoleName.ADMIN:
        from sqlalchemy import select
        from app.models.request_assignment import RequestAssignment
        from sqlalchemy.orm import joinedload

        rows = list(
            db.scalars(
                select(RequestAssignment)
                .options(joinedload(RequestAssignment.request))
                .order_by(RequestAssignment.id.desc())
            )
        )
    else:
        rows = assignment_crud.list_for_member(db, current_user.id)
    return [_to_out(r) for r in rows]


@router.patch("/{assignment_id}", response_model=AssignmentOut)
def update_task_status(
    assignment_id: int,
    body: AssignmentStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    row = assignment_crud.get(db, assignment_id)
    if not row:
        raise HTTPException(status_code=404, detail="Assignment not found")
    if (
        current_user.role.role_name != RoleName.ADMIN
        and row.member_id != current_user.id
    ):
        raise HTTPException(status_code=403, detail="Not your assignment")
    row = assignment_crud.update_status(db, row, body.status)
    return _to_out(row)
