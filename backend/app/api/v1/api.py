from fastapi import APIRouter
from app.api.v1.endpoints import auth, alerts, community, priority_contacts

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(alerts.router, prefix="/emergency", tags=["emergency"])
api_router.include_router(community.router, prefix="/communities", tags=["community"])
api_router.include_router(priority_contacts.router, prefix="/priority-contacts", tags=["priority-contacts"])
