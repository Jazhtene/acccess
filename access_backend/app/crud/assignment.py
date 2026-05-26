"""request_assignments + documentation_requests for members."""

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.documentation_request import DocumentationRequest
from app.models.request_assignment import RequestAssignment


def list_for_member(db: Session, member_id: int) -> list[RequestAssignment]:
    return list(
        db.scalars(
            select(RequestAssignment)
            .options(
                joinedload(RequestAssignment.request),
                joinedload(RequestAssignment.member),
            )
            .where(RequestAssignment.member_id == member_id)
            .order_by(RequestAssignment.id.desc())
        )
    )


def get(db: Session, assignment_id: int) -> RequestAssignment | None:
    return db.scalar(
        select(RequestAssignment)
        .options(joinedload(RequestAssignment.request))
        .where(RequestAssignment.id == assignment_id)
    )


def update_status(db: Session, assignment: RequestAssignment, status: str) -> RequestAssignment:
    assignment.status = status.strip().lower()
    db.commit()
    db.refresh(assignment)
    return assignment
