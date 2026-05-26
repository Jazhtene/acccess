"""media_files CRUD."""

from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload

from app.models.media_file import MediaFile


def list_media(
    db: Session,
    *,
    uploaded_by: int | None = None,
    file_type: str | None = None,
    search: str | None = None,
    request_id: int | None = None,
) -> list[MediaFile]:
    q = select(MediaFile).options(
        joinedload(MediaFile.evaluations),
        joinedload(MediaFile.ai_detection_results),
        joinedload(MediaFile.uploader),
    )
    if uploaded_by is not None:
        q = q.where(MediaFile.uploaded_by == uploaded_by)
    if file_type:
        q = q.where(MediaFile.file_type == file_type)
    if request_id is not None:
        q = q.where(MediaFile.request_id == request_id)
    if search:
        term = f"%{search.strip()}%"
        q = q.where(or_(MediaFile.file_name.ilike(term), MediaFile.file_type.ilike(term)))
    q = q.order_by(MediaFile.uploaded_at.desc())
    return list(db.scalars(q).unique())


def get(db: Session, media_id: int) -> MediaFile | None:
    return db.scalar(
        select(MediaFile)
        .options(
            joinedload(MediaFile.evaluations),
            joinedload(MediaFile.ai_detection_results),
            joinedload(MediaFile.comments),
        )
        .where(MediaFile.id == media_id)
    )


def delete_media(db: Session, media: MediaFile) -> None:
    db.delete(media)
    db.commit()


def create(db: Session, data: dict) -> MediaFile:
    row = MediaFile(**data)
    db.add(row)
    db.commit()
    db.refresh(row)
    return get(db, row.id)  # type: ignore[arg-type]
