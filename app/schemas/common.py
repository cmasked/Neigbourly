"""Common response schemas."""

from pydantic import BaseModel
from typing import Any


class MessageResponse(BaseModel):
    message: str


class ErrorResponse(BaseModel):
    detail: str
    error_code: str | None = None


class PaginatedResponse(BaseModel):
    data: list[Any]
    next_cursor: str | None = None
    has_more: bool = False
    total: int | None = None
