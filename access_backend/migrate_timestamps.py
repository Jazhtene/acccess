"""
Add updated_at columns for models using TimestampMixin (existing PostgreSQL DBs).

Run from access_backend/:
  python migrate_timestamps.py
"""

from dotenv import load_dotenv

load_dotenv()

from sqlalchemy import text

from app.database import engine

TABLES = (
    "users",
    "documentation_requests",
    "event_calendar",
    "ai_detection_results",
    "notifications",
    "feedbacks",
    "announcements",
    "media_comments",
    "user_sessions",
    "audit_logs",
)


def main() -> None:
    with engine.begin() as conn:
        for table in TABLES:
            conn.execute(
                text(
                    f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS "
                    "updated_at TIMESTAMPTZ DEFAULT NOW()"
                )
            )
            print(f"  -> {table}.updated_at OK")
    print("Timestamp migration complete.")


if __name__ == "__main__":
    main()
