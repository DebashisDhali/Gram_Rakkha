from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.core.config import settings

# Engine configuration
if settings.DATABASE_URL.startswith("sqlite"):
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=True,
        connect_args={"check_same_thread": False},
    )
else:
    # Postgres configuration (Neon / RDS)
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=True, 
        pool_size=10,
        max_overflow=20,
        pool_recycle=3600,
        pool_pre_ping=True,
    )

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

async def get_db():
    # Dependency for FastAPI endpoints
    async with SessionLocal() as session:
        yield session
