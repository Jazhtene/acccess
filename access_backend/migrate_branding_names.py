"""
Add system name columns to system_branding (safe to run multiple times).

Usage:
  cd access_backend
  python migrate_branding_names.py
"""

from sqlalchemy import text

from app.database import engine


def main() -> None:
    statements = [
        "ALTER TABLE system_branding ADD COLUMN IF NOT EXISTS app_name VARCHAR(120)",
        "ALTER TABLE system_branding ADD COLUMN IF NOT EXISTS tagline VARCHAR(255)",
        "ALTER TABLE system_branding ADD COLUMN IF NOT EXISTS short_tagline VARCHAR(255)",
        "ALTER TABLE system_branding ADD COLUMN IF NOT EXISTS organization VARCHAR(120)",
    ]
    with engine.begin() as conn:
        for sql in statements:
            conn.execute(text(sql))
    print("system_branding name columns OK.")


if __name__ == "__main__":
    main()
