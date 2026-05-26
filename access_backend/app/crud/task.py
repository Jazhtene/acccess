from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.task import Task


def list_tasks(db: Session, assigned_to: int | None = None) -> list[Task]:
    q = select(Task).order_by(Task.created_at.desc())
    if assigned_to:
        q = q.where(Task.assigned_to == assigned_to)
    return list(db.scalars(q))


def create(db: Session, data: dict, created_by: int) -> Task:
    row = Task(**data, created_by=created_by)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
