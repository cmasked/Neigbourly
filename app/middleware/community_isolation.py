"""
Neighborhood isolation enforcement.
Provides the community_id scoping for all queries.
"""

from app.middleware.auth import CurrentUser


def get_community_id(current_user: CurrentUser) -> str:
    """Extract community_id from authenticated user — used to scope all DB queries."""
    return current_user.community_id
