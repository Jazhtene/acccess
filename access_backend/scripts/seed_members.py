"""Add demo member accounts to an existing database (idempotent). Run from access_backend/."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dotenv import load_dotenv

load_dotenv()

from app.database import SessionLocal
from create_tables import seed_extra_members, seed_member_demo, seed_roles, seed_skill_levels
from app.seed.sample_data import seed_sample_dataset

if __name__ == "__main__":
    db = SessionLocal()
    try:
        role_ids = seed_roles(db)
        skill_ids = seed_skill_levels(db)
        seed_extra_members(db, role_ids, skill_ids)
        seed_member_demo(db)
        seed_sample_dataset(db)
        print("Done. Refresh Members, Rankings, and Dashboard in the admin app.")
    finally:
        db.close()
