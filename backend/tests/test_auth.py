import pytest
from app.models.user import User
from app.core import security
from uuid import uuid4

def test_password_hashing():
    password = "secret_password"
    hashed = security.get_password_hash(password)
    assert security.verify_password(password, hashed)
    assert not security.verify_password("wrong_password", hashed)

def test_user_creation():
    user_id = uuid4()
    user = User(
        id=user_id,
        full_name="Test User",
        phone_number="+1234567890",
        hashed_password="hashed_content"
    )
    assert user.full_name == "Test User"
    assert user.phone_number == "+1234567890"
    assert user.id == user_id
