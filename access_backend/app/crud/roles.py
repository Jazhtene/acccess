"""Role catalog for admin Roles & Permissions page."""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.role import Role
from app.models.user import User

ROLE_DESCRIPTIONS: dict[str, str] = {
    "Admin": "Full access to the web admin dashboard, approvals, and system settings.",
    "Member": "Mobile app access for documentation uploads, tasks, and rankings.",
    "Organization": "Submit documentation requests and view org-related activity.",
}

ROLE_PERMISSIONS: dict[str, list[str]] = {
    "Admin": [
        "manage_members",
        "approve_requests",
        "manage_media",
        "manage_roles",
        "view_analytics",
        "manage_events",
        "ai_review",
        "export_reports",
    ],
    "Member": [
        "upload_media",
        "view_tasks",
        "view_rankings",
        "submit_feedback",
    ],
    "Organization": [
        "submit_documentation_requests",
        "view_request_status",
        "submit_feedback",
    ],
}


def list_roles_with_stats(db: Session) -> list[dict]:
    """PostgreSQL roles with user counts and permission metadata."""
    roles = db.scalars(select(Role).order_by(Role.id.asc())).all()
    result: list[dict] = []
    for role in roles:
        name = role.role_name
        user_count = (
            db.scalar(select(func.count()).select_from(User).where(User.role_id == role.id)) or 0
        )
        result.append(
            {
                "id": role.id,
                "role_name": name,
                "name": name,
                "description": ROLE_DESCRIPTIONS.get(name, f"{name} role"),
                "permissions": ROLE_PERMISSIONS.get(name, []),
                "status": "active",
                "user_count": user_count,
            }
        )
    return result
