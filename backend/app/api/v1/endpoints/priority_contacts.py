from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.db.session import get_db
from app.models.user import User
from app.schemas.priority_contact import PriorityContactOut, PriorityContactCreate
from app.repositories.priority_contact_repository import PriorityContactRepository
from app.repositories.user_repository import UserRepository
import uuid

router = APIRouter()

@router.get("/", response_model=List[PriorityContactOut])
async def get_priority_contacts(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Retrieve all priority contacts for current user."""
    repo = PriorityContactRepository(db)
    return await repo.get_user_priority_contacts(current_user.id)

@router.post("/", response_model=PriorityContactOut)
async def add_priority_contact(
    contact_in: PriorityContactCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Add a user to priority contacts list."""
    if current_user.id == contact_in.contact_user_id:
        raise HTTPException(status_code=400, detail="Cannot add yourself as a priority contact.")
    
    repo = PriorityContactRepository(db)
    # Check if contact user exists
    user_repo = UserRepository(db)
    contact_user = await user_repo.get(contact_in.contact_user_id)
    if not contact_user:
        raise HTTPException(status_code=404, detail="User not found.")
        
    try:
        new_contact = await repo.add_contact(current_user.id, contact_in.contact_user_id)
        await db.commit()
        # Refresh to get contact_user relationship
        return await repo.get(new_contact.id)
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Contact already exists in your list.")

@router.delete("/{contact_user_id}")
async def remove_priority_contact(
    contact_user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Remove a user from priority contacts list."""
    repo = PriorityContactRepository(db)
    success = await repo.remove_contact(current_user.id, contact_user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Contact not found in your list.")
    await db.commit()
    return {"status": "success"}

@router.get("/search/{phone}", response_model=Any)
async def search_user_by_phone(
    phone: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Search for a user by phone number to add them."""
    user_repo = UserRepository(db)
    user = await user_repo.get_by_phone(phone)
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return {
        "id": str(user.id),
        "full_name": user.full_name,
        "phone_number": user.phone_number
    }
