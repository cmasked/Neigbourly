"""
Simple in-memory rate limiter middleware.
For production, swap with Redis-based implementation.
"""

import time
from collections import defaultdict
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from app.config import get_settings

settings = get_settings()


class RateLimiterMiddleware(BaseHTTPMiddleware):
    """Token-bucket rate limiter per IP address."""

    def __init__(self, app, requests_per_minute: int = None):
        super().__init__(app)
        self.rpm = requests_per_minute or settings.RATE_LIMIT_PER_MINUTE
        self.requests: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        if request.url.path.startswith("/static/") or request.url.path == "/":
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.time()
        window_start = now - 60

        # Clean old entries
        self.requests[client_ip] = [
            t for t in self.requests[client_ip] if t > window_start
        ]

        if len(self.requests[client_ip]) >= self.rpm:
            return Response(
                content='{"detail":"Rate limit exceeded. Try again later."}',
                status_code=429,
                media_type="application/json",
            )

        self.requests[client_ip].append(now)
        response = await call_next(request)
        return response
