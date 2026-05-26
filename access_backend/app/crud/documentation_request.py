from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.documentation_request import DocumentationRequest


def create(db: Session, requestor_id: int, data: dict) -> DocumentationRequest:
    row = DocumentationRequest(requestor_id=requestor_id, **data)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_for_user(db: Session, user_id: int) -> list[DocumentationRequest]:
    return list(
        db.scalars(
            select(DocumentationRequest)
            .options(joinedload(DocumentationRequest.requestor))
            .where(DocumentationRequest.requestor_id == user_id)
            .order_by(DocumentationRequest.created_at.desc())
        )
    )


def list_all(db: Session) -> list[DocumentationRequest]:
    return list(
        db.scalars(
            select(DocumentationRequest)
            .options(joinedload(DocumentationRequest.requestor))
            .order_by(DocumentationRequest.created_at.desc())
        )
    )


def get(db: Session, request_id: int) -> DocumentationRequest | None:
    return db.scalar(
        select(DocumentationRequest)
        .options(joinedload(DocumentationRequest.requestor))
        .where(DocumentationRequest.id == request_id)
    )


def update_status(
    db: Session,
    row: DocumentationRequest,
    status: str,
    rejection_reason: str | None = None,
) -> DocumentationRequest:
    row.status = status.strip().lower()
    if rejection_reason:
        row.rejection_reason = rejection_reason
    db.commit()
    db.refresh(row)
    return row
