from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.models.priority_contact import PriorityContact
from app.services.websocket_manager import manager
import uuid

class AlertService:
    @staticmethod
    async def broadcast_alert(db: AsyncSession, reporter_id: uuid.UUID, alert_data: dict):
        # 1. Find Priority Contacts
        query = select(PriorityContact.contact_user_id).where(PriorityContact.user_id == reporter_id)
        result = await db.execute(query)
        priority_ids = [str(row[0]) for row in result.all()]
        
        # 2. WebSocket message
        message = {
            "event": "PRIORITY_ALERT",
            "payload": {
                **alert_data,
                "is_priority": True,
                "reporter_id": str(reporter_id)
            }
        }
        
        # 3. Direct Message to Priority
        for uid in priority_ids:
            await manager.send_personal_message(message, uid)
            
        # 4. Message to Reporter (Confirmation)
        await manager.send_personal_message({"event": "ALERT_SENT", "status": "sent"}, str(reporter_id))
        
        # Note: Broad broadcast to full community happens AFTER verification logic (omitted for MVP brevity)
        return True

    @staticmethod
    async def broadcast_to_community(db: AsyncSession, community_id: uuid.UUID, alert_data: dict):
        # Find all users in communal distance (simplistic for MVP)
        query = select(User.id).where(User.community_id == community_id)
        result = await db.execute(query)
        uids = [str(row[0]) for row in result.all()]
        
        message = {
            "event": "COMMUNITY_ALERT",
            "payload": alert_data
        }
        
        for uid in uids:
            await manager.send_personal_message(message, uid)
