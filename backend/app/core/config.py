from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "GramRaksha"
    API_V1_STR: str = "/api/v1"
    
    # SECURITY
    SECRET_KEY: str = "DEVELOPMENT_SECRET_KEY_REPLACE_IN_PRODUCTION"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    ALGORITHM: str = "HS256"
    
    # DATABASE (Local SQLite by default for immediate functionality, switch to Neon/Postgres for production)
    # Production example: postgresql+asyncpg://user:password@host:port/dbname
    DATABASE_URL: str = "sqlite+aiosqlite:///./gram_raksha.db"
    
    # REDIS (Upstash or Local Docker)
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"] # Allow all for MVP, restrict in prod

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
