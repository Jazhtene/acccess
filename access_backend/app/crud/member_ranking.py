from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.member_ranking import MemberRanking


def get_or_create(db: Session, user_id: int) -> MemberRanking:
    row = db.scalar(select(MemberRanking).where(MemberRanking.user_id == user_id))
    if row:
        return row
    row = MemberRanking(user_id=user_id, total_points=0, rank_position=None)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def add_points(db: Session, user_id: int, points: int) -> MemberRanking:
    row = get_or_create(db, user_id)
    row.total_points += max(0, points)
    db.commit()
    db.refresh(row)
    _recompute_ranks(db)
    db.refresh(row)
    return row


def _recompute_ranks(db: Session) -> None:
    rows = list(
        db.scalars(select(MemberRanking).order_by(MemberRanking.total_points.desc()))
    )
    for idx, row in enumerate(rows, start=1):
        row.rank_position = idx
    db.commit()
