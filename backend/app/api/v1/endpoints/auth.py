from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from app.db.session import get_db
from app.repositories.user_repository import UserRepository
from app.core import security
from app.schemas.user import UserCreate, Token, UserOut
from app.models.user import User
from app.api.deps import get_current_active_user

router = APIRouter()

class LoginRequest(BaseModel):
    phone_number: str
    password: str

@router.post("/register", response_model=UserOut)
async def register(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    user_repo = UserRepository(db)
    user_exists = await user_repo.get_by_phone(user_in.phone_number)
    if user_exists:
        raise HTTPException(status_code=400, detail="User already exists with this phone number")
    
    new_user = User(
        full_name=user_in.full_name,
        phone_number=user_in.phone_number,
        hashed_password=security.get_password_hash(user_in.password),
        home_lat=user_in.home_lat,
        home_lng=user_in.home_lng
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.post("/login", response_model=Token)
async def login(login_data: LoginRequest, db: AsyncSession = Depends(get_db)):
    user_repo = UserRepository(db)
    user = await user_repo.get_by_phone(login_data.phone_number)
    if not user or not security.verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone number or password",
        )
    
    access_token = security.create_access_token(subject=str(user.id))
    refresh_token = security.create_refresh_token(subject=str(user.id))
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_active_user)):
    """Returns the currently authenticated user's profile."""
    return current_user
