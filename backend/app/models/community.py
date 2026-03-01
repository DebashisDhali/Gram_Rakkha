import uuid
from sqlalchemy import String, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base

class Community(Base):
    __tablename__ = "communities"
    
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    
    # Radius in KM for the community boundary
    radius_km: Mapped[float] = mapped_column(default=5.0)
    
    center_lat: Mapped[float] = mapped_column(nullable=True)
    center_lng: Mapped[float] = mapped_column(nullable=True)
    
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
