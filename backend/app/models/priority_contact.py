import uuid
from sqlalchemy import ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base_class import Base

class PriorityContact(Base):
    __tablename__ = "priority_contacts"
    
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    contact_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    contact_user: Mapped["User"] = relationship("User", foreign_keys=[contact_user_id])
    
    # Ensure a user can't add the same contact twice
    __table_args__ = (
        UniqueConstraint('user_id', 'contact_user_id', name='_user_contact_uc'),
    )
