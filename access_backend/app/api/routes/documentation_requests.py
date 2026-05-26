"""Documentation / service requests."""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.api.deps import require_admin, require_approved
from app.crud import documentation_request as req_crud
from app.database import get_db
from app.models.enums import RoleName
from app.models.user import User

router = APIRouter(tags=["Documentation Requests"])


class ServiceRequestCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    event_date: date
    venue: str | None = None


class ServiceRequestOut(BaseModel):
    id: int
    requestor_id: int
    title: str
    description: str | None
    event_date: date
    venue: str | None
    status: str

    model_config = {"from_attributes": True}


class ServiceRequestStatusUpdate(BaseModel):
    status: str
    rejection_reason: str | None = None


@router.get("/service-requests", response_model=list[ServiceRequestOut])
def list_service_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    if current_user.role.role_name == RoleName.ADMIN:
        return req_crud.list_all(db)
    return req_crud.list_for_user(db, current_user.id)


@router.post("/service-requests", response_model=ServiceRequestOut)
def create_service_request(
    body: ServiceRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    row = req_crud.create(
        db,
        current_user.id,
        body.model_dump(),
    )
    from app.services import notification_events as notify_events

    requestor_name = current_user.fullname or current_user.email
    notify_events.notify_documentation_request_submitted(db, row.id, row.title, requestor_name)
    return row


@router.patch("/service-requests/{request_id}")
def update_service_request_status(
    request_id: int,
    body: ServiceRequestStatusUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    row = req_crud.get(db, request_id)
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")
    req_crud.update_status(db, row, body.status, body.rejection_reason)
    from app.services import notification_events as notify_events

    notify_events.notify_documentation_request_status(
        db, row.requestor_id, row.id, row.title, body.status
    )
    return {"message": f"Request {body.status}"}
