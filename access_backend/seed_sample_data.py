"""
Load ACCESS sample rows into PostgreSQL (not hardcoded in the Flutter app).

Usage (from access_backend/):
  .\\venv\\Scripts\\Activate.ps1
  python seed_sample_data.py

Requires tables and default users from create_tables.py first.
"""

from dotenv import load_dotenv

load_dotenv()

from app.database import SessionLocal
from app.seed.sample_data import seed_sample_dataset


def main() -> None:
    print("ACCESS — seeding PostgreSQL sample data...")
    db = SessionLocal()
    try:
        seed_sample_dataset(db)
        print()
        print("Done. Refresh the admin dashboard and mobile app to see live API data.")
        print("Login: admin@access.edu / admin123")
    finally:
        db.close()


if __name__ == "__main__":
    main()
