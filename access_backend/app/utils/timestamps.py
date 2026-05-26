"""Safe ISO timestamps for API responses when columns may be missing."""

from __future__ import annotations

from datetime import datetime
from typing import Any


def iso_timestamp(value: datetime | None) -> str | None:
    if value is None:
        return None
    try:
        return value.isoformat()
    except (AttributeError, TypeError, ValueError):
        return None


def first_timestamp_iso(obj: Any, *field_names: str) -> str | None:
    """Return ISO string from the first non-null datetime attribute on obj."""
    for name in field_names:
        value = getattr(obj, name, None)
        if value is not None:
            result = iso_timestamp(value)
            if result:
                return result
    return None
