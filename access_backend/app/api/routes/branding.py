"""Public branding endpoints (logo + system display names)."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.crud import system_branding as branding_crud
from app.database import get_db

router = APIRouter(prefix="/branding", tags=["Branding"])


@router.get("")
def get_branding(db: Session = Depends(get_db)):
    """Logo URL and resolved system names (public)."""
    return branding_crud.branding_payload(db)


@router.get("/logo")
def get_logo(db: Session = Depends(get_db)):
    """Backward-compatible alias — same payload as GET /branding."""
    return branding_crud.branding_payload(db)
