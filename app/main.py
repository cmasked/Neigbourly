"""
Neighborly — Main Application Entry Point
FastAPI application with all routers, middleware, and lifecycle hooks.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.middleware.rate_limiter import RateLimiterMiddleware

# Import all controllers
from app.controllers.auth_controller import router as auth_router
from app.controllers.item_controller import router as item_router
from app.controllers.rental_request_controller import router as rental_request_router
from app.controllers.transaction_controller import router as transaction_router
from app.controllers.payment_controller import router as payment_router
from app.controllers.dispute_controller import router as dispute_router
from app.controllers.review_controller import router as review_router

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifecycle."""
    # Startup
    print(f"{settings.APP_NAME} starting in {settings.APP_ENV} mode")
    print(f"Database: {settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}")
    yield
    # Shutdown
    print(f"{settings.APP_NAME} shutting down")


app = FastAPI(
    title="Neighborly API",
    description="Neighborhood local sharing platform — peer-to-peer rentals with local isolation, escrow payments, and trust scoring.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ─── Middleware ──────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(RateLimiterMiddleware)


@app.middleware("http")
async def disable_frontend_cache(request: Request, call_next):
    """Prevent stale frontend assets from being served from browser cache during development."""
    response = await call_next(request)
    if request.url.path == "/" or request.url.path.startswith("/static/"):
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
    return response

# ─── Global Exception Handler ───────────────────────────────

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all exception handler for unhandled errors."""
    if hasattr(exc, "status_code"):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": str(exc.detail), "error_code": getattr(exc, "error_code", "ERROR")},
        )
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error_code": "INTERNAL_ERROR"},
    )

# ─── API Routes ──────────────────────────────────────────────

API_PREFIX = "/api/v1"

app.include_router(auth_router, prefix=API_PREFIX)
app.include_router(item_router, prefix=API_PREFIX)
app.include_router(rental_request_router, prefix=API_PREFIX)
app.include_router(transaction_router, prefix=API_PREFIX)
app.include_router(payment_router, prefix=API_PREFIX)
app.include_router(dispute_router, prefix=API_PREFIX)
app.include_router(review_router, prefix=API_PREFIX)

# Serve Frontend static files
from pathlib import Path
frontend_dir = Path(__file__).parent.parent / "frontend"
app.mount("/static", StaticFiles(directory=str(frontend_dir)), name="static")

@app.get("/")
async def serve_frontend():
    return FileResponse(str(frontend_dir / "index.html"))

# ─── Health Check ────────────────────────────────────────────

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": "1.0.0",
    }


@app.get("/api")
async def root():
    """Root endpoint with API information."""
    return {
        "name": settings.APP_NAME,
        "description": "Neighborhood local sharing API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }
