"""Post to a Facebook Page via Graph API (credentials from .env)."""

from __future__ import annotations

import json
import mimetypes
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from app.config import settings

GRAPH_VERSION = "v21.0"
GRAPH_BASE = f"https://graph.facebook.com/{GRAPH_VERSION}"


class FacebookServiceError(Exception):
    """Raised when Graph API or configuration fails."""

    def __init__(self, code: str, message: str):
        self.code = code
        super().__init__(message)


def _page_id() -> str:
    pid = (settings.facebook_page_id or "").strip()
    if not pid:
        raise FacebookServiceError(
            "invalid_page_id",
            "FACEBOOK_PAGE_ID is not set in .env.",
        )
    return pid


def _access_token() -> str:
    token = (settings.facebook_page_access_token or "").strip()
    if not token:
        raise FacebookServiceError(
            "missing_token",
            "FACEBOOK_PAGE_ACCESS_TOKEN is not set in .env.",
        )
    return token


def _request_json(method: str, url: str, data: dict | None = None, files: dict | None = None) -> dict:
    if files:
        from io import BytesIO

        boundary = "----AccessVisionCheckBoundary"
        body = BytesIO()
        for key, (filename, file_bytes, content_type) in files.items():
            body.write(f"--{boundary}\r\n".encode())
            body.write(
                f'Content-Disposition: form-data; name="{key}"; filename="{filename}"\r\n'.encode()
            )
            body.write(f"Content-Type: {content_type}\r\n\r\n".encode())
            body.write(file_bytes)
            body.write(b"\r\n")
        if data:
            for key, value in data.items():
                body.write(f"--{boundary}\r\n".encode())
                body.write(f'Content-Disposition: form-data; name="{key}"\r\n\r\n'.encode())
                body.write(f"{value}\r\n".encode())
        body.write(f"--{boundary}--\r\n".encode())
        req = urllib.request.Request(
            url,
            data=body.getvalue(),
            method=method,
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        )
    elif data:
        encoded = urllib.parse.urlencode(data).encode()
        req = urllib.request.Request(url, data=encoded, method=method)
    else:
        req = urllib.request.Request(url, method=method)

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        try:
            payload = json.loads(exc.read().decode())
            err = payload.get("error", {})
            msg = err.get("message", str(exc))
            code = err.get("code", exc.code)
            raise FacebookServiceError("graph_api_error", f"Facebook API error ({code}): {msg}") from exc
        except (json.JSONDecodeError, UnicodeDecodeError):
            raise FacebookServiceError("graph_api_error", f"Facebook API HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise FacebookServiceError("network_error", f"Could not reach Facebook: {exc.reason}") from exc


def resolve_image_source(file_url: str, file_type: str) -> tuple[str | None, Path | None]:
    """Return (public_http_url, local_file_path) for image media."""
    if file_type == "video":
        return None, None
    if not file_url or not file_url.strip():
        return None, None

    url = file_url.strip()
    if url.startswith("http://") or url.startswith("https://"):
        return url, None

    rel = url.lstrip("/")
    if rel.startswith("uploads/"):
        rel = rel[len("uploads/") :]
    local = Path(settings.upload_dir) / rel
    if local.is_file():
        public = f"{settings.public_api_url.rstrip('/')}/{url.lstrip('/')}"
        return public, local

    public = f"{settings.public_api_url.rstrip('/')}/{url.lstrip('/')}"
    return public, None


def post_to_facebook(message: str, image_url: str | None = None, *, local_path: Path | None = None) -> str:
    """
    Publish to the configured Facebook Page.
    Returns the Graph API post/photo id.
    """
    page_id = _page_id()
    token = _access_token()
    text = (message or "").strip() or "Shared from ACCESS VisionCheck"

    if image_url or local_path:
        endpoint = f"{GRAPH_BASE}/{page_id}/photos"
        if local_path and local_path.is_file():
            content = local_path.read_bytes()
            ctype = mimetypes.guess_type(str(local_path))[0] or "application/octet-stream"
            data = {"message": text, "access_token": token}
            result = _request_json(
                "POST",
                endpoint,
                data=data,
                files={"source": (local_path.name, content, ctype)},
            )
        else:
            if not image_url:
                raise FacebookServiceError(
                    "image_unreachable",
                    "Image URL is missing or the file is not on disk.",
                )
            result = _request_json(
                "POST",
                endpoint,
                data={"url": image_url, "message": text, "access_token": token},
            )
    else:
        endpoint = f"{GRAPH_BASE}/{page_id}/feed"
        result = _request_json(
            "POST",
            endpoint,
            data={"message": text, "access_token": token},
        )

    post_id = result.get("post_id") or result.get("id")
    if not post_id:
        raise FacebookServiceError("graph_api_error", "Facebook did not return a post id.")
    return str(post_id)
