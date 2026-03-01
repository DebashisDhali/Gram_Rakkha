from typing import Dict, Set, Any
from fastapi import WebSocket
import json

class ConnectionManager:
    def __init__(self):
        # user_id -> set of active websockets (handles multi-device)
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_personal_message(self, message: Any, user_id: str):
        if user_id in self.active_connections:
            dead_connections = set()
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(message)
                except Exception:
                    dead_connections.add(connection)
            
            for dead in dead_connections:
                self.active_connections[user_id].discard(dead)

    async def broadcast(self, message: Any):
        for user_id in list(self.active_connections.keys()):
            await self.send_personal_message(message, user_id)

manager = ConnectionManager()
