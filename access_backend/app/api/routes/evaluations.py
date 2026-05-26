from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import require_approved
from app.crud import evaluation as eval_crud
from app.database import get_db
from app.models.user import User
from app.schemas.member_api import EvaluationOut

router = APIRouter(prefix="/evaluations", tags=["Evaluations"])


@router.get("", response_model=list[EvaluationOut])
def list_evaluations(
    mine: bool = True,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_approved),
):
    rows = eval_crud.list_for_user(db, current_user.id) if mine else []
    result = []
    for ev in rows:
        ai = eval_crud.get_ai_for_media(db, ev.media_id)
        result.append(
            EvaluationOut(
                id=ev.id,
                media_id=ev.media_id,
                file_name=ev.media.file_name,
                file_url=ev.media.file_url,
                sharpness_score=ev.sharpness_score,
                brightness_score=ev.brightness_score,
                contrast_score=ev.contrast_score,
                blur_score=ev.blur_score,
                noise_score=ev.noise_score,
                overall_score=ev.overall_score,
                feedback=ev.feedback,
                evaluated_at=ev.evaluated_at,
                ai_probability=ai.ai_probability if ai else None,
                detection_result=ai.detection_result if ai else None,
                quality_level=ev.quality_level,
                recommendation=ev.recommendation,
                criteria_json=ev.criteria_json,
            )
        )
    return result
