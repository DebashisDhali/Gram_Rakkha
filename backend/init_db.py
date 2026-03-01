import asyncio
from app.db.base_class import Base
from app.db.session import engine
from app.models.user import User
from app.models.alert import Alert, Verification
from app.models.community import Community
from app.models.priority_contact import PriorityContact

async def init_db():
    async with engine.begin() as conn:
        # This will create all tables based on the models
        await conn.run_sync(Base.metadata.create_all)
    print("Database tables created successfully.")

if __name__ == "__main__":
    asyncio.run(init_db())
