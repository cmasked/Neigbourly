"""
Security utilities — JWT tokens, password hashing, PII encryption.
"""

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
import bcrypt
from cryptography.fernet import Fernet

from app.config import get_settings

settings = get_settings()


# ─── Password Hashing ──────────────────────────────────────

def hash_password(password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a plaintext password against a bcrypt hash."""
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


# ─── JWT Tokens ─────────────────────────────────────────────

def create_access_token(user_id: str, community_id: str, role: str) -> str:
    """Create a short-lived access token (default 15 min)."""
    payload = {
        "sub": user_id,
        "community_id": community_id,
        "role": role,
        "type": "access",
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES),
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(user_id: str) -> str:
    """Create a long-lived refresh token (default 7 days)."""
    payload = {
        "sub": user_id,
        "type": "refresh",
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS),
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> dict[str, Any]:
    """Decode and validate a JWT token. Raises jwt.PyJWTError on failure."""
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


# ─── PII Encryption ────────────────────────────────────────

def _get_cipher() -> Fernet:
    """Get Fernet cipher from config key (must be base64-encoded 32 bytes)."""
    return Fernet(settings.ENCRYPTION_KEY.encode("utf-8"))


def encrypt_pii(value: str) -> str:
    """Encrypt a PII field value."""
    cipher = _get_cipher()
    return cipher.encrypt(value.encode("utf-8")).decode("utf-8")


def decrypt_pii(encrypted: str) -> str:
    """Decrypt a PII field value."""
    cipher = _get_cipher()
    return cipher.decrypt(encrypted.encode("utf-8")).decode("utf-8")
