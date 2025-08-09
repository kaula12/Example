from fastapi import WebSocket
from typing import Dict, List, Set
import json
from datetime import datetime

class ConnectionManager:
    def __init__(self):
        # Store active connections by restaurant_id
        self.active_connections: Dict[int, Set[WebSocket]] = {}
        # Store user connections for direct messaging
        self.user_connections: Dict[int, WebSocket] = {}
        # Store connection metadata
        self.connection_metadata: Dict[WebSocket, Dict] = {}
    
    async def connect(self, websocket: WebSocket, restaurant_id: int, user_id: int = None, user_role: str = "customer"):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        
        # Add to restaurant connections
        if restaurant_id not in self.active_connections:
            self.active_connections[restaurant_id] = set()
        self.active_connections[restaurant_id].add(websocket)
        
        # Add to user connections if user_id provided
        if user_id:
            self.user_connections[user_id] = websocket
        
        # Store metadata
        self.connection_metadata[websocket] = {
            "restaurant_id": restaurant_id,
            "user_id": user_id,
            "user_role": user_role,
            "connected_at": datetime.utcnow()
        }
        
        print(f"WebSocket connected: Restaurant {restaurant_id}, User {user_id}, Role {user_role}")
    
    def disconnect(self, websocket: WebSocket):
        """Remove a WebSocket connection"""
        metadata = self.connection_metadata.get(websocket, {})
        restaurant_id = metadata.get("restaurant_id")
        user_id = metadata.get("user_id")
        
        # Remove from restaurant connections
        if restaurant_id and restaurant_id in self.active_connections:
            self.active_connections[restaurant_id].discard(websocket)
            if not self.active_connections[restaurant_id]:
                del self.active_connections[restaurant_id]
        
        # Remove from user connections
        if user_id and user_id in self.user_connections:
            del self.user_connections[user_id]
        
        # Remove metadata
        if websocket in self.connection_metadata:
            del self.connection_metadata[websocket]
        
        print(f"WebSocket disconnected: Restaurant {restaurant_id}, User {user_id}")
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        """Send a message to a specific WebSocket connection"""
        try:
            message_with_timestamp = {
                **message,
                "timestamp": datetime.utcnow().isoformat()
            }
            await websocket.send_text(json.dumps(message_with_timestamp))
        except Exception as e:
            print(f"Error sending personal message: {e}")
            self.disconnect(websocket)
    
    async def send_to_user(self, user_id: int, message: dict):
        """Send a message to a specific user"""
        if user_id in self.user_connections:
            await self.send_personal_message(message, self.user_connections[user_id])
    
    async def broadcast_to_restaurant(self, restaurant_id: int, message: dict):
        """Broadcast a message to all connections in a restaurant"""
        if restaurant_id in self.active_connections:
            message_with_timestamp = {
                **message,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            disconnected_connections = []
            
            for connection in self.active_connections[restaurant_id].copy():
                try:
                    await connection.send_text(json.dumps(message_with_timestamp))
                except Exception as e:
                    print(f"Error broadcasting to restaurant {restaurant_id}: {e}")
                    disconnected_connections.append(connection)
            
            # Clean up disconnected connections
            for connection in disconnected_connections:
                self.disconnect(connection)
    
    async def broadcast_to_role(self, restaurant_id: int, role: str, message: dict):
        """Broadcast a message to all connections with a specific role in a restaurant"""
        if restaurant_id in self.active_connections:
            message_with_timestamp = {
                **message,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            disconnected_connections = []
            
            for connection in self.active_connections[restaurant_id].copy():
                metadata = self.connection_metadata.get(connection, {})
                if metadata.get("user_role") == role:
                    try:
                        await connection.send_text(json.dumps(message_with_timestamp))
                    except Exception as e:
                        print(f"Error broadcasting to role {role} in restaurant {restaurant_id}: {e}")
                        disconnected_connections.append(connection)
            
            # Clean up disconnected connections
            for connection in disconnected_connections:
                self.disconnect(connection)
    
    def get_restaurant_connections_count(self, restaurant_id: int) -> int:
        """Get the number of active connections for a restaurant"""
        return len(self.active_connections.get(restaurant_id, set()))
    
    def get_connection_info(self, websocket: WebSocket) -> dict:
        """Get metadata for a specific connection"""
        return self.connection_metadata.get(websocket, {})
    
    def get_all_connections_info(self) -> dict:
        """Get information about all active connections"""
        info = {}
        for restaurant_id, connections in self.active_connections.items():
            info[restaurant_id] = {
                "connection_count": len(connections),
                "connections": [
                    self.connection_metadata.get(conn, {})
                    for conn in connections
                ]
            }
        return info

# Global connection manager instance
manager = ConnectionManager()

