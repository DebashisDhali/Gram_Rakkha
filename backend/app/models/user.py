import uuid
from sqlalchemy import String, Boolean, DateTime, Float
from sqlalchemy.sql import func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone_number: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Simple coordinates for MVP, but spatial indexing recommended for production (PostGIS)
    home_lat: Mapped[float] = mapped_column(Float, nullable=True)
    home_lng: Mapped[float] = mapped_column(Float, nullable=True)
    
    community_id: Mapped[uuid.UUID] = mapped_column(nullable=True, index=True)
    
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
