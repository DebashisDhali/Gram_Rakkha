from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime
from app.schemas.user import UserOut

class PriorityContactBase(BaseModel):
    contact_user_id: UUID

class PriorityContactCreate(PriorityContactBase):
    pass

class PriorityContactOut(BaseModel):
    id: UUID
    user_id: UUID
    contact_user_id: UUID
    created_at: datetime
    contact_user: UserOut
    
    model_config = ConfigDict(from_attributes=True)
