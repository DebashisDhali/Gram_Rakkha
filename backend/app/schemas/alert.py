from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime
from app.models.alert import AlertType, AlertStatus

class AlertBase(BaseModel):
    type: AlertType
    lat: float
    lng: float

class AlertCreate(AlertBase):
    pass

class AlertOut(AlertBase):
    id: UUID
    reporter_id: UUID
    status: AlertStatus
    timestamp: datetime
    model_config = ConfigDict(from_attributes=True)

class VerificationCreate(BaseModel):
    alert_id: UUID

class VerificationOut(BaseModel):
    id: UUID
    alert_id: UUID
    verifier_id: UUID
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
