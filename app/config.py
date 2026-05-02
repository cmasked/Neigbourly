"""
Neighborly — Application Configuration
Loads settings from environment variables with sensible defaults.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from .env file."""

    # App
    APP_NAME: str = "Neighborly"
    APP_ENV: str = "development"
    APP_DEBUG: bool = True
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000

    # MySQL Database
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_NAME: str = "neighborly"
    DB_USER: str = "neighborly_user"
    DB_PASSWORD: str = "neighborly_pass"
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20

    @property
    def DATABASE_URL(self) -> str:
        return (
            f"mysql+aiomysql://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            f"?charset=utf8mb4"
        )

    @property
    def DATABASE_URL_SYNC(self) -> str:
        return (
            f"mysql+mysqldb://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            f"?charset=utf8mb4"
        )

    # JWT
    JWT_SECRET_KEY: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Celery
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/1"

    # File Storage
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_MB: int = 10

    # Encryption
    ENCRYPTION_KEY: str = "your-32-byte-encryption-key-here"

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # Trust Score
    TRUST_SCORE_INITIAL: int = 50
    TRUST_SCORE_MIN: int = 0
    TRUST_SCORE_MAX: int = 100

    # Commission
    PLATFORM_COMMISSION_RATE: float = 10.0  # percentage

    model_config = {
        "env_file": ".env",
        "case_sensitive": True,
        "extra": "ignore",
    }


@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()
