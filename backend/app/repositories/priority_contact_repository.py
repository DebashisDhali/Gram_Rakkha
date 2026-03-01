import uuid
from typing import List
from sqlalchemy import select, delete
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.base import BaseRepository
from app.models.priority_contact import PriorityContact
from app.models.user import User

class PriorityContactRepository(BaseRepository[PriorityContact]):
    def __init__(self, db: AsyncSession):
        super().__init__(PriorityContact, db)

    async def get_user_priority_contacts(self, user_id: uuid.UUID) -> List[PriorityContact]:
        query = (
            select(PriorityContact)
            .where(PriorityContact.user_id == user_id)
            .options(joinedload(PriorityContact.contact_user))
        )
        # Note: I need to check if PriorityContact has a relationship to User
        # Let me check the model again.
        result = await self.db.execute(query)
        return result.scalars().all()

    async def add_contact(self, user_id: uuid.UUID, contact_user_id: uuid.UUID) -> PriorityContact:
        contact = PriorityContact(user_id=user_id, contact_user_id=contact_user_id)
        self.db.add(contact)
        await self.db.flush()
        return contact

    async def remove_contact(self, user_id: uuid.UUID, contact_user_id: uuid.UUID) -> bool:
        query = delete(PriorityContact).where(
            PriorityContact.user_id == user_id,
            PriorityContact.contact_user_id == contact_user_id
        )
        result = await self.db.execute(query)
        return result.rowcount > 0
