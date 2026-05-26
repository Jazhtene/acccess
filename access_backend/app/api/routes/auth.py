"""Single login API for Admin (Web) and Member/Organization (Mobile)."""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.security import create_access_token, verify_password
from app.crud import session as session_crud
from app.crud import user as user_crud
from app.database import get_db
from app.models.enums import RoleName, UserStatus
from app.models.user import User
from app.schemas.auth import LoginRequest, LoginResponse, RegisterRequest, UserOut
from app.schemas.common import MessageResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _redirect_hint(role_name: str) -> str:
    """Flutter uses this to know which platform to open after login."""
    if role_name == RoleName.ADMIN:
        return "web_admin"
    return "mobile_app"


def _user_out(user: User) -> UserOut:
    return UserOut(
        id=user.id,
        name=user.fullname,
        email=user.email,
        role=user.role.role_name,
    )


@router.post("/login", response_model=LoginResponse)
def login(body: LoginRequest, request: Request, db: Session = Depends(get_db)):
    existing = user_crud.get_by_email(db, body.email)
    if existing and verify_password(body.password, existing.password) and not existing.is_active:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={
                "error": "removed",
                "message": "Your account has been removed. Please contact the administrator.",
            },
        )

    user = user_crud.authenticate(db, body.email, body.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if user.status == UserStatus.PENDING:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={
                "error": "pending",
                "message": "Your account is still pending admin approval.",
            },
        )
    if user.status == UserStatus.REJECTED:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={
                "error": "rejected",
                "message": "Your account registration was rejected. Please contact the administrator.",
            },
        )

    role_name = user.role.role_name
    token = create_access_token({
        "userId": user.id,
        "name": user.fullname,
        "email": user.email,
        "role": role_name,
    })
    client_host = request.client.host if request.client else None
    device = request.headers.get("user-agent", "unknown")[:255]
    session_crud.record_login(db, user.id, ip_address=client_host, device_info=device)
    session_crud.create_session(db, user.id, token)

    return LoginResponse(
        token=token,
        user=_user_out(user),
        redirect_hint=_redirect_hint(role_name),
    )


@router.post("/logout", response_model=MessageResponse)
def logout(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_crud.revoke_sessions_for_user(db, current_user.id)
    return MessageResponse(message="Logged out")


@router.post("/register", response_model=MessageResponse)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if user_crud.get_by_email(db, body.email):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    user_crud.create_user(
        db,
        body.name,
        body.email,
        body.password,
        body.role,
        student_id=body.student_id,
        contact_number=body.contact_number,
        adviser_name=body.adviser_name,
        skill_level=body.skill_level,
    )
    return MessageResponse(message="Registration submitted. Awaiting admin approval.")
