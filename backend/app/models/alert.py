import uuid
from enum import Enum as PyEnum
from sqlalchemy import String, DateTime, Float, ForeignKey, Enum as SqlEnum
from sqlalchemy.sql import func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base_class import Base

class AlertType(str, PyEnum):
    DANGER = "danger"
    SUSPICIOUS = "suspicious"
    HELP = "help"

class AlertStatus(str, PyEnum):
    PENDING = "pending"
    VERIFIED = "verified"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"

class Alert(Base):
    __tablename__ = "alerts"
    
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    reporter_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    
    type: Mapped[AlertType] = mapped_column(SqlEnum(AlertType), nullable=False)
    status: Mapped[AlertStatus] = mapped_column(SqlEnum(AlertStatus), default=AlertStatus.PENDING)
    
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    
    timestamp: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships omitted for brevity, add as needed

class Verification(Base):
    __tablename__ = "verifications"
    
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    alert_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("alerts.id"), index=True)
    verifier_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
