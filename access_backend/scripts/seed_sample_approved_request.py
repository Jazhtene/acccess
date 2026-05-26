"""Insert one approved documentation request (idempotent). Run from access_backend/."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dotenv import load_dotenv

load_dotenv()

from app.database import SessionLocal
from create_tables import seed_sample_approved_documentation

if __name__ == "__main__":
    db = SessionLocal()
    try:
        seed_sample_approved_documentation(db)
        print("Done. Refresh Gallery in the admin app.")
    finally:
        db.close()
