from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.db.session import get_db
from app.services.websocket_manager import manager
from app.models.user import User
from app.models.alert import Alert
from app.schemas.alert import AlertCreate, AlertOut
from app.repositories.alert_repository import AlertRepository
from app.repositories.user_repository import UserRepository
from app.repositories.priority_contact_repository import PriorityContactRepository
import uuid

router = APIRouter()

@router.post("/", response_model=AlertOut)
async def create_alert(
    alert_in: AlertCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    alert_repo = AlertRepository(db)
    # 1. Persist the alert
    # Logic: For production, we'd use a transaction and background task
    new_alert = Alert(
        reporter_id=current_user.id,
        type=alert_in.type,
        lat=alert_in.lat,
        lng=alert_in.lng
    )
    db.add(new_alert)
    await db.flush()
    
    # 2. Targeted Notify
    user_repo = UserRepository(db)
    priority_repo = PriorityContactRepository(db)
    
    # Get nearby users (within 500m)
    nearby_users = await user_repo.get_nearby_users(alert_in.lat, alert_in.lng, radius_km=0.5)
    nearby_user_ids = {str(u.id) for u in nearby_users}
    
    # Get priority contacts
    priority_contacts = await priority_repo.get_user_priority_contacts(current_user.id)
    priority_ids = {str(c.contact_user_id) for c in priority_contacts}
    
    # Final target list (set handles duplicates)
    target_ids = nearby_user_ids.union(priority_ids)
    # Always notify the reporter (for confirmation UI)
    target_ids.add(str(current_user.id))
    
    alert_msg = {
        "event": "EMERGENCY_ALERT",
        "payload": {
            "id": str(new_alert.id),
            "type": new_alert.type.value,
            "location": {"lat": new_alert.lat, "lng": new_alert.lng},
            "reporter": current_user.full_name,
            "reporter_id": str(current_user.id),
            "timestamp": str(new_alert.timestamp)
        }
    }
    
    # Notify targeted users
    for user_id in target_ids:
        await manager.send_personal_message(alert_msg, user_id)
    
    await db.commit()
    await db.refresh(new_alert)
    return new_alert

@router.websocket("/ws/{token}")
async def alert_websocket(websocket: WebSocket, token: str):
    try:
        user_id = deps.verify_ws_token(token)
    except:
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, user_id)
    try:
        while True:
            # Low-latency heartbeats or simple receipt
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
