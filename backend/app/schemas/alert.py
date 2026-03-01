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
