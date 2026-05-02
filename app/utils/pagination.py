"""Cursor-based pagination utility."""

from typing import Any, TypeVar, Generic
from pydantic import BaseModel

T = TypeVar("T")


class PaginationParams(BaseModel):
    """Pagination query parameters."""
    cursor: str | None = None
    limit: int = 20

    def validate_limit(self) -> int:
        return min(max(self.limit, 1), 100)


class PaginatedResponse(BaseModel):
    """Paginated response wrapper."""
    data: list[Any]
    next_cursor: str | None = None
    has_more: bool = False
    total: int | None = None


def encode_cursor(value: str) -> str:
    """Encode a cursor value (simple base64 for now)."""
    import base64
    return base64.urlsafe_b64encode(value.encode()).decode()


def decode_cursor(cursor: str) -> str:
    """Decode a cursor value."""
    import base64
    return base64.urlsafe_b64decode(cursor.encode()).decode()
