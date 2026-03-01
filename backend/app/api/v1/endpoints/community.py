from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.db.session import get_db
from app.models.community import Community
from app.models.user import User
from pydantic import BaseModel
import uuid

router = APIRouter()

class CommunityCreate(BaseModel):
    name: str
    center_lat: float
    center_lng: float
    radius_km: float = 5.0

@router.post("/create")
async def create_community(
    comm_in: CommunityCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    new_comm = Community(
        name=comm_in.name,
        center_lat=comm_in.center_lat,
        center_lng=comm_in.center_lng,
        radius_km=comm_in.radius_km
    )
    db.add(new_comm)
    await db.flush()
    
    # Auto-assign creator to community
    current_user.community_id = new_comm.id
    db.add(current_user)
    
    await db.commit()
    await db.refresh(new_comm)
    return new_comm

@router.post("/join/{community_id}")
async def join_community(
    community_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
):
    comm = await db.get(Community, community_id)
    if not comm:
        raise HTTPException(status_code=404, detail="Community not found")
        
    current_user.community_id = comm.id
    db.add(current_user)
    await db.commit()
    return {"status": "joined", "community": comm.name}
