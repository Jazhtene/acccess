from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import feedback as feedback_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import FeedbackCreate, FeedbackOut

router = APIRouter(prefix="/feedback", tags=["Feedback"])


@router.get("", response_model=list[FeedbackOut])
def list_feedback(
    request_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    return feedback_crud.list_feedbacks(db, user_id=current_user.id, request_id=request_id)


@router.post("", response_model=FeedbackOut)
def submit_feedback(
    body: FeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    row = feedback_crud.create(
        db,
        {
            "request_id": body.request_id,
            "user_id": current_user.id,
            "rating": body.rating,
            "comment": body.comment,
        },
    )
    from app.crud.documentation_request import get as get_doc_req
    from app.services import notification_events as notify_events

    doc = get_doc_req(db, body.request_id)
    event_title = doc.title if doc else f"Request #{body.request_id}"
    notify_events.notify_feedback_submitted(
        db,
        row.id,
        event_title,
        body.rating,
        current_user.fullname or current_user.email,
    )
    return row
