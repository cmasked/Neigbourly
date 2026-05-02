"""
Item controller — CRUD and search endpoints.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.item import (
    CreateItemRequest, UpdateItemRequest, SetAvailabilityRequest,
    ItemResponse, ItemSearchRequest,
)
from app.schemas.common import MessageResponse
from app.services.item_service import ItemService
from app.middleware.auth import get_current_user, get_verified_user, CurrentUser

router = APIRouter(prefix="/items", tags=["Items"])


@router.post("", response_model=ItemResponse, status_code=201)
async def create_item(
    body: CreateItemRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new item listing."""
    service = ItemService(db, current_user.community_id)
    item = await service.create_item(
        owner_id=current_user.user_id, **body.model_dump()
    )
    return ItemResponse.model_validate(item)


@router.get("", response_model=list[ItemResponse])
async def list_items(
    cursor: str | None = None,
    limit: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List items in the community."""
    service = ItemService(db, current_user.community_id)
    items = await service.list_items(cursor=cursor, limit=limit)
    return [ItemResponse.model_validate(i) for i in items[:limit]]


@router.get("/search")
async def search_items(
    q: str | None = None,
    category: str | None = None,
    min_price: float | None = None,
    max_price: float | None = None,
    cursor: str | None = None,
    limit: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Search items with full-text search and filters."""
    service = ItemService(db, current_user.community_id)
    result = await service.search_items(
        query=q, category=category,
        min_price=min_price, max_price=max_price,
        cursor=cursor, limit=limit,
    )
    result["data"] = [ItemResponse.model_validate(i) for i in result["data"]]
    return result


@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get item details."""
    service = ItemService(db, current_user.community_id)
    item = await service.get_item(item_id)
    return ItemResponse.model_validate(item)


@router.put("/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: str,
    body: UpdateItemRequest,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Update an item listing (owner only)."""
    service = ItemService(db, current_user.community_id)
    updates = body.model_dump(exclude_unset=True)
    item = await service.update_item(item_id, current_user.user_id, **updates)
    return ItemResponse.model_validate(item)


@router.delete("/{item_id}", response_model=MessageResponse)
async def delete_item(
    item_id: str,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Soft-delete an item (owner only)."""
    service = ItemService(db, current_user.community_id)
    await service.delete_item(item_id, current_user.user_id)
    return MessageResponse(message="Item deleted")


@router.post("/{item_id}/availability", status_code=201)
async def set_availability(
    item_id: str,
    body: SetAvailabilityRequest,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Set availability window for an item."""
    service = ItemService(db, current_user.community_id)
    avail = await service.set_availability(
        item_id, current_user.user_id,
        body.start_date, body.end_date,
        body.is_blocked, body.reason,
    )
    return {"id": avail.id, "message": "Availability set"}
