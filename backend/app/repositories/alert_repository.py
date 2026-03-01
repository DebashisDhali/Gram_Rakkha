from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.base import BaseRepository
from app.models.alert import Alert

class AlertRepository(BaseRepository[Alert]):
    def __init__(self, db: AsyncSession):
        super().__init__(Alert, db)
