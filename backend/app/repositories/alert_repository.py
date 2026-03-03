from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.base import BaseRepository
from app.models.alert import Alert, Verification

class AlertRepository(BaseRepository[Alert]):
    def __init__(self, db: AsyncSession):
        super().__init__(Alert, db)

    async def verify_alert(self, alert_id: str, verifier_id: str) -> Verification:
        verification = Verification(alert_id=alert_id, verifier_id=verifier_id)
        self.db.add(verification)
        return verification

    async def get_verifications_count(self, alert_id: str) -> int:
        query = select(func.count(Verification.id)).where(Verification.alert_id == alert_id)
        result = await self.db.execute(query)
        return result.scalar_one()

    async def get_priority_verifications_count(self, alert_id: str, priority_ids: list) -> int:
        query = select(func.count(Verification.id)).where(
            Verification.alert_id == alert_id,
            Verification.verifier_id.in_(priority_ids)
        )
        result = await self.db.execute(query)
        return result.scalar_one()
