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
    new_alert = Alert(
        reporter_id=current_user.id,
        type=alert_in.type,
        lat=alert_in.lat,
        lng=alert_in.lng
    )
    db.add(new_alert)
    await db.flush()
    
    # Notify Priority Contacts first
    priority_repo = PriorityContactRepository(db)
    priority_contacts = await priority_repo.get_user_priority_contacts(current_user.id)
    priority_ids = {str(c.contact_user_id) for c in priority_contacts}
    
    # Always notify the reporter
    target_ids = priority_ids.union({str(current_user.id)})
    
    alert_msg = {
        "event": "EMERGENCY_ALERT",
        "payload": {
            "id": str(new_alert.id),
            "type": new_alert.type.value,
            "status": new_alert.status.value,
            "location": {"lat": new_alert.lat, "lng": new_alert.lng},
            "reporter": current_user.full_name,
            "reporter_id": str(current_user.id),
            "timestamp": str(new_alert.timestamp)
        }
    }
    
    for user_id in target_ids:
        await manager.send_personal_message(alert_msg, user_id)
    
    await db.commit()
    await db.refresh(new_alert)
    return new_alert

@router.post("/{alert_id}/verify", response_model=AlertOut)
async def verify_alert(
    alert_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    alert_repo = AlertRepository(db)
    alert = await alert_repo.get(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    # Check if already verified
    if alert.status == "verified":
         return alert

    # Persist verification
    await alert_repo.verify_alert(str(alert_id), str(current_user.id))
    await db.flush()
    
    # Check if verifications from priority contacts reach threshold (2)
    priority_repo = PriorityContactRepository(db)
    priority_contacts = await priority_repo.get_user_priority_contacts(alert.reporter_id)
    priority_ids = [c.contact_user_id for c in priority_contacts]
    
    p_verify_count = await alert_repo.get_priority_verifications_count(str(alert_id), priority_ids)
    
    if p_verify_count >= 2:
        # ESCALATE TO ALL USERS
        from app.models.alert import AlertStatus
        alert.status = AlertStatus.VERIFIED
        await db.flush()
        
        # Notify ALL users
        user_repo = UserRepository(db)
        all_users = await user_repo.list()
        
        alert_msg = {
            "event": "ALERT_VERIFIED",
            "payload": {
                "id": str(alert.id),
                "type": alert.type.value,
                "status": alert.status.value,
                "location": {"lat": alert.lat, "lng": alert.lng},
                "reporter_id": str(alert.reporter_id),
                "timestamp": str(alert.timestamp)
            }
        }
        for u in all_users:
            await manager.send_personal_message(alert_msg, str(u.id))
            
    await db.commit()
    await db.refresh(alert)
    return alert

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
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
