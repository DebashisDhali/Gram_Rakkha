import uuid
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

class CommunityBase(BaseModel):
    name: str
    center_lat: float
    center_lng: float
    radius_km: float

class CommunityCreate(CommunityBase):
    pass

class CommunityOut(CommunityBase):
    id: uuid.UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

class PriorityContactCreate(BaseModel):
    contact_user_id: uuid.UUID

class PriorityContactOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    contact_user_id: uuid.UUID
    created_at: datetime
    
    class Config:
        from_attributes = True
