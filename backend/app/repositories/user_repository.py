from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.base import BaseRepository
from app.models.user import User

class UserRepository(BaseRepository[User]):
    def __init__(self, db: AsyncSession):
        super().__init__(User, db)

    async def get_by_phone(self, phone: str) -> Optional[User]:
        query = select(User).where(User.phone_number == phone)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_nearby_users(self, lat: float, lng: float, radius_km: float = 0.5) -> List[User]:
        """Fetch users within a radius of a location."""
        # SQLite doesn't have spatial functions, so we calculate roughly
        # 1 deg lat = 111km
        # 1 deg lng = 111km * cos(lat)
        
        lat_delta = radius_km / 111.0
        # Roughly estimate lng delta (assuming mid-lat)
        lng_delta = radius_km / (111.0 * 0.7) 
        
        query = select(User).where(
            User.home_lat >= lat - lat_delta,
            User.home_lat <= lat + lat_delta,
            User.home_lng >= lng - lng_delta,
            User.home_lng <= lng + lng_delta
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def search_users(self, query_str: str, limit: int = 10) -> List[User]:
        """Search users by name or phone number."""
        query = select(User).where(
            (User.full_name.ilike(f"%{query_str}%")) | 
            (User.phone_number.contains(query_str))
        ).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())
