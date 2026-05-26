"""
Idempotent PostgreSQL sample data for ACCESS admin + mobile UIs.

Run after tables exist:
  python seed_sample_data.py

Or automatically from create_tables.py on fresh setup.
"""

from __future__ import annotations

from datetime import date, time, timedelta

from sqlalchemy.orm import Session

from app.crud import analytics as analytics_crud
from app.models.ai_detection_result import AiDetectionResult
from app.models.analytics_report import AnalyticsReport
from app.models.documentation_request import DocumentationRequest
from app.models.event_calendar import EventCalendar
from app.models.feedback import Feedback
from app.models.media_evaluation import MediaEvaluation
from app.models.media_file import MediaFile
from app.models.notification import Notification
from app.models.request_assignment import RequestAssignment
from app.models.role import Role
from app.models.user import User


def _user(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()


def _member_ids(db: Session) -> list[User]:
    role = db.query(Role).filter(Role.role_name == "Member").first()
    if not role:
        return []
    return (
        db.query(User)
        .filter(User.role_id == role.id, User.status == "approved")
        .order_by(User.id.asc())
        .all()
    )


def _ensure_request(
    db: Session,
    *,
    title: str,
    requestor_id: int,
    status: str,
    event_date: date,
    venue: str,
    description: str,
    rejection_reason: str | None = None,
) -> DocumentationRequest:
    row = db.query(DocumentationRequest).filter(DocumentationRequest.title == title).first()
    if row:
        row.status = status
        row.rejection_reason = rejection_reason
        row.venue = venue
        row.description = description
        row.event_date = event_date
        db.flush()
        return row
    row = DocumentationRequest(
        requestor_id=requestor_id,
        title=title,
        description=description,
        event_date=event_date,
        venue=venue,
        status=status,
        rejection_reason=rejection_reason,
    )
    db.add(row)
    db.flush()
    return row


def _ensure_event(
    db: Session,
    *,
    title: str,
    start_date: date,
    venue: str,
    status: str,
    request_id: int | None = None,
    assigned_member_id: int | None = None,
    description: str | None = None,
    start_time: time | None = None,
    end_time: time | None = None,
) -> EventCalendar:
    row = db.query(EventCalendar).filter(EventCalendar.title == title).first()
    if row:
        row.status = status
        row.start_date = start_date
        row.venue = venue
        row.request_id = request_id
        row.assigned_member_id = assigned_member_id
        row.description = description
        row.start_time = start_time
        row.end_time = end_time
        db.flush()
        return row
    row = EventCalendar(
        title=title,
        description=description,
        start_date=start_date,
        venue=venue,
        status=status,
        request_id=request_id,
        assigned_member_id=assigned_member_id,
        start_time=start_time,
        end_time=end_time,
    )
    db.add(row)
    db.flush()
    return row


def _ensure_media(
    db: Session,
    *,
    file_name: str,
    request_id: int,
    uploaded_by: int,
    file_type: str = "image/jpeg",
) -> MediaFile:
    row = db.query(MediaFile).filter(MediaFile.file_name == file_name).first()
    if row:
        return row
    row = MediaFile(
        uploaded_by=uploaded_by,
        request_id=request_id,
        file_name=file_name,
        file_type=file_type,
        file_url=f"/uploads/samples/{file_name}",
    )
    db.add(row)
    db.flush()
    return row


def _ensure_evaluation(
    db: Session,
    media: MediaFile,
    *,
    sharpness: float,
    brightness: float,
    contrast: float,
    blur: float,
    noise: float,
    overall: float,
    feedback: str,
) -> MediaEvaluation:
    row = db.query(MediaEvaluation).filter(MediaEvaluation.media_id == media.id).first()
    if row:
        row.sharpness_score = sharpness
        row.brightness_score = brightness
        row.contrast_score = contrast
        row.blur_score = blur
        row.noise_score = noise
        row.overall_score = overall
        row.feedback = feedback
        db.flush()
        return row
    row = MediaEvaluation(
        media_id=media.id,
        sharpness_score=sharpness,
        brightness_score=brightness,
        contrast_score=contrast,
        blur_score=blur,
        noise_score=noise,
        overall_score=overall,
        feedback=feedback,
    )
    db.add(row)
    db.flush()
    return row


def _ensure_ai_result(
    db: Session,
    media: MediaFile,
    *,
    probability: float,
    detection_result: str,
    review_status: str = "pending_review",
    admin_remarks: str | None = None,
) -> AiDetectionResult:
    row = db.query(AiDetectionResult).filter(AiDetectionResult.media_id == media.id).first()
    if row:
        row.ai_probability = probability
        row.detection_result = detection_result
        row.review_status = review_status
        row.admin_remarks = admin_remarks
        db.flush()
        return row
    row = AiDetectionResult(
        media_id=media.id,
        ai_probability=probability,
        detection_result=detection_result,
        review_status=review_status,
        admin_remarks=admin_remarks,
        detection_remarks="Automated pipeline scan (sample seed).",
    )
    db.add(row)
    db.flush()
    return row


def _ensure_feedback(
    db: Session,
    *,
    request_id: int,
    user_id: int,
    rating: int,
    comment: str,
) -> None:
    exists = (
        db.query(Feedback)
        .filter(Feedback.request_id == request_id, Feedback.user_id == user_id)
        .first()
    )
    if exists:
        exists.rating = rating
        exists.comment = comment
        return
    db.add(
        Feedback(
            request_id=request_id,
            user_id=user_id,
            rating=rating,
            comment=comment,
        )
    )


def _ensure_assignment(
    db: Session,
    *,
    request_id: int,
    member_id: int,
    assigned_by: int,
    task_role: str,
    status: str,
) -> None:
    row = (
        db.query(RequestAssignment)
        .filter(
            RequestAssignment.request_id == request_id,
            RequestAssignment.member_id == member_id,
        )
        .first()
    )
    if row:
        row.status = status
        row.task_role = task_role
        return
    db.add(
        RequestAssignment(
            request_id=request_id,
            member_id=member_id,
            assigned_by=assigned_by,
            task_role=task_role,
            status=status,
        )
    )


def _ensure_notification(
    db: Session,
    *,
    user_id: int,
    title: str,
    message: str,
    category: str = "system_alert",
    priority: str = "normal",
    is_read: bool = False,
) -> None:
    exists = (
        db.query(Notification)
        .filter(Notification.user_id == user_id, Notification.title == title)
        .first()
    )
    if exists:
        return
    db.add(
        Notification(
            user_id=user_id,
            title=title,
            message=message,
            category=category,
            priority=priority,
            is_read=is_read,
        )
    )


def _seed_documentation_requests(db: Session, admin: User, org: User | None) -> dict[str, DocumentationRequest]:
    today = date.today()
    requestor_org = org.id if org else admin.id
    specs = [
        ("USTP Founders Day", "approved", today + timedelta(days=7), "Main Gymnasium", requestor_org, None),
        ("Acquaintance Party Coverage", "pending", today + timedelta(days=21), "Student Lounge", requestor_org, None),
        ("Engineering Week Opening", "approved", today + timedelta(days=14), "CoE AVR", admin.id, None),
        ("Intramurals Opening Ceremony", "rejected", today + timedelta(days=30), "Sports Complex", requestor_org, "Insufficient crew available."),
        ("Leadership Summit 2026", "completed", today - timedelta(days=3), "AVR Hall B", admin.id, None),
        ("Sample Approved Event", "approved", today + timedelta(days=14), "USTP Oroquieta Campus", admin.id, None),
    ]
    out: dict[str, DocumentationRequest] = {}
    for title, status, ev_date, venue, req_id, rejection in specs:
        out[title] = _ensure_request(
            db,
            title=title,
            requestor_id=req_id,
            status=status,
            event_date=ev_date,
            venue=venue,
            description=f"Sample documentation request: {title}.",
            rejection_reason=rejection,
        )
    db.commit()
    return out


def _seed_events(db: Session, requests: dict[str, DocumentationRequest], members: list[User]) -> None:
    today = date.today()
    assign = members[0].id if members else None
    events = [
        ("USTP Founders Day", today + timedelta(days=7), "Main Gymnasium", "upcoming", requests["USTP Founders Day"].id, assign, time(8, 0), time(17, 0)),
        ("Engineering Week Opening", today + timedelta(days=14), "CoE AVR", "assigned", requests["Engineering Week Opening"].id, members[1].id if len(members) > 1 else assign, time(9, 0), time(12, 0)),
        ("Leadership Summit 2026", today - timedelta(days=3), "AVR Hall B", "completed", requests["Leadership Summit 2026"].id, members[2].id if len(members) > 2 else assign, time(13, 0), time(16, 30)),
        ("General Assembly", today + timedelta(days=28), "ICT Building", "upcoming", None, None, time(14, 0), time(16, 0)),
        ("Photo Editing Workshop", today + timedelta(days=35), "Media Lab", "pending_documentation", None, assign, time(10, 0), time(12, 0)),
    ]
    for title, start, venue, status, req_id, member_id, st, et in events:
        _ensure_event(
            db,
            title=title,
            start_date=start,
            venue=venue,
            status=status,
            request_id=req_id,
            assigned_member_id=member_id,
            description=f"Calendar entry for {title}.",
            start_time=st,
            end_time=et,
        )
    db.commit()


def _seed_assignments(db: Session, admin: User, requests: dict[str, DocumentationRequest], members: list[User]) -> None:
    founders = requests["USTP Founders Day"]
    summit = requests["Leadership Summit 2026"]
    pairs = [
        (founders, "member@access.edu", "photographer", "assigned"),
        (founders, "carlos.m@student.ustp.edu.ph", "videographer", "assigned"),
        (founders, "maria.santos@student.ustp.edu.ph", "editor", "assigned"),
        (founders, "sophia.lim@student.ustp.edu.ph", "photographer", "completed"),
        (summit, "james.villanueva@student.ustp.edu.ph", "lead photographer", "completed"),
        (summit, "miguel.torres@student.ustp.edu.ph", "videographer", "completed"),
    ]
    for req, email, role, status in pairs:
        member = _user(db, email)
        if member:
            _ensure_assignment(
                db,
                request_id=req.id,
                member_id=member.id,
                assigned_by=admin.id,
                task_role=role,
                status=status,
            )
    db.commit()


def _seed_media_and_evaluations(db: Session, requests: dict[str, DocumentationRequest], members: list[User]) -> None:
    if not members:
        return
    uploader = _user(db, "carlos.m@student.ustp.edu.ph") or members[0]
    approved_req = requests.get("Sample Approved Event") or requests["Engineering Week Opening"]
    summit_req = requests["Leadership Summit 2026"]

    media_specs = [
        ("founders_day_01.jpg", approved_req.id, uploader.id, 0.85, 0.76, 0.79, 0.12, 0.08, 0.82, "human", "verified_human", "Clear coverage shots."),
        ("founders_day_02.jpg", approved_req.id, uploader.id, 0.72, 0.68, 0.70, 0.18, 0.10, 0.71, "human", "verified_human", None),
        ("engineering_week_04.jpg", approved_req.id, uploader.id, 0.68, 0.55, 0.62, 0.22, 0.15, 0.58, "suspicious", "needs_further_review", "Lighting inconsistent — review recommended."),
        ("summit_keynote.jpg", summit_req.id, uploader.id, 0.91, 0.88, 0.90, 0.05, 0.04, 0.90, "human", "verified_human", "Excellent keynote coverage."),
        ("summit_ai_flagged.jpg", summit_req.id, uploader.id, 0.55, 0.50, 0.52, 0.35, 0.20, 0.48, "ai_generated", "pending_review", "High AI probability — awaiting admin review."),
    ]
    for (
        fname,
        req_id,
        uid,
        sharp,
        bright,
        contrast,
        blur,
        noise,
        overall,
        detection,
        review_status,
        remarks,
    ) in media_specs:
        media = _ensure_media(db, file_name=fname, request_id=req_id, uploaded_by=uid)
        _ensure_evaluation(
            db,
            media,
            sharpness=sharp,
            brightness=bright,
            contrast=contrast,
            blur=blur,
            noise=noise,
            overall=overall,
            feedback=remarks or "Sample evaluation from seed data.",
        )
        _ensure_ai_result(
            db,
            media,
            probability=0.92 if detection == "ai_generated" else 0.08,
            detection_result=detection,
            review_status=review_status,
            admin_remarks=remarks,
        )
    db.commit()


def _seed_feedback(db: Session, requests: dict[str, DocumentationRequest], members: list[User]) -> None:
    summit = requests["Leadership Summit 2026"]
    founders = requests["USTP Founders Day"]
    reviewers = [
        ("org@access.edu", 5, "Outstanding documentation and timely delivery."),
        ("member@access.edu", 4, "Great team coordination during the event."),
        ("maria.santos@student.ustp.edu.ph", 3, "Good photos; could improve indoor low-light shots."),
    ]
    for email, rating, comment in reviewers:
        user = _user(db, email)
        if user:
            _ensure_feedback(db, request_id=summit.id, user_id=user.id, rating=rating, comment=comment)
    org = _user(db, "org@access.edu")
    if org and members:
        _ensure_feedback(
            db,
            request_id=founders.id,
            user_id=org.id,
            rating=5,
            comment="Approved for campus publication.",
        )
    db.commit()


def _seed_notifications(db: Session, admin: User, members: list[User]) -> None:
    _ensure_notification(
        db,
        user_id=admin.id,
        title="Pending documentation requests",
        message="Acquaintance Party Coverage is awaiting admin review.",
        category="documentation_request",
        priority="high",
    )
    _ensure_notification(
        db,
        user_id=admin.id,
        title="AI detection alert",
        message="summit_ai_flagged.jpg flagged as possible AI-generated content.",
        category="ai_detection",
        priority="high",
    )
    _ensure_notification(
        db,
        user_id=admin.id,
        title="New feedback submitted",
        message="Leadership Summit 2026 received a 5-star rating.",
        category="feedback",
        priority="normal",
        is_read=True,
    )
    if members:
        _ensure_notification(
            db,
            user_id=members[0].id,
            title="Task assigned",
            message="You were assigned as photographer for USTP Founders Day.",
            category="task_assignment",
            priority="normal",
        )
    db.commit()


def _seed_analytics_snapshot(db: Session) -> None:
    """Store dashboard counts in analytics_reports for the admin analytics page."""
    stats = analytics_crud.dashboard_stats(db)
    latest = db.query(AnalyticsReport).order_by(AnalyticsReport.generated_at.desc()).first()
    if latest and latest.total_members == stats["total_members"] and latest.total_requests == stats["total_requests"]:
        return
    db.add(
        AnalyticsReport(
            total_requests=stats["total_requests"],
            total_media=stats["media_uploads"],
            total_members=stats["total_members"],
        )
    )
    db.commit()


def seed_sample_dataset(db: Session) -> None:
    """Insert or refresh PostgreSQL sample rows (safe to run multiple times)."""
    admin = _user(db, "admin@access.edu")
    if not admin:
        print("  ! Skipping sample data — run create_tables.py first (admin@access.edu missing).")
        return

    org = _user(db, "org@access.edu")
    members = _member_ids(db)

    print("  -> Seeding documentation requests...")
    requests = _seed_documentation_requests(db, admin, org)

    print("  -> Seeding calendar events...")
    _seed_events(db, requests, members)

    print("  -> Seeding task assignments...")
    _seed_assignments(db, admin, requests, members)

    print("  -> Seeding media, evaluations, and AI detection...")
    _seed_media_and_evaluations(db, requests, members)

    print("  -> Seeding feedback...")
    _seed_feedback(db, requests, members)

    print("  -> Seeding notifications...")
    _seed_notifications(db, admin, members)

    print("  -> Recording analytics snapshot...")
    _seed_analytics_snapshot(db)

    print("  -> Sample database seed complete.")
