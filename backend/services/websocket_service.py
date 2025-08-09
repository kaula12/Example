from fastapi import WebSocket
from typing import List, Dict
import json
from datetime import datetime

class ConnectionManager:
    def __init__(self):
        # Store connections by restaurant_id
        self.active_connections: Dict[int, List[WebSocket]] = {}
        # Store connections by user role for targeted messaging
        self.connections_by_role: Dict[str, List[WebSocket]] = {}
        # Store user info for each connection
        self.connection_info: Dict[WebSocket, Dict] = {}
    
    async def connect(self, websocket: WebSocket, restaurant_id: int, user_role: str = None, user_id: int = None):
        await websocket.accept()
        
        # Store connection info
        self.connection_info[websocket] = {
            "restaurant_id": restaurant_id,
            "user_role": user_role,
            "user_id": user_id,
            "connected_at": datetime.now()
        }
        
        # Add to restaurant connections
        if restaurant_id not in self.active_connections:
            self.active_connections[restaurant_id] = []
        self.active_connections[restaurant_id].append(websocket)
        
        # Add to role-based connections
        if user_role:
            if user_role not in self.connections_by_role:
                self.connections_by_role[user_role] = []
            self.connections_by_role[user_role].append(websocket)
    
    def disconnect(self, websocket: WebSocket, restaurant_id: int = None, user_role: str = None):
        # Get connection info if not provided
        if websocket in self.connection_info:
            info = self.connection_info[websocket]
            restaurant_id = restaurant_id or info.get("restaurant_id")
            user_role = user_role or info.get("user_role")
            del self.connection_info[websocket]
        
        # Remove from restaurant connections
        if restaurant_id and restaurant_id in self.active_connections:
            if websocket in self.active_connections[restaurant_id]:
                self.active_connections[restaurant_id].remove(websocket)
            
            # Clean up empty lists
            if not self.active_connections[restaurant_id]:
                del self.active_connections[restaurant_id]
        
        # Remove from role-based connections
        if user_role and user_role in self.connections_by_role:
            if websocket in self.connections_by_role[user_role]:
                self.connections_by_role[user_role].remove(websocket)
            
            # Clean up empty lists
            if not self.connections_by_role[user_role]:
                del self.connections_by_role[user_role]
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        try:
            await websocket.send_text(json.dumps(message))
        except:
            # Connection might be closed, remove it
            self.disconnect(websocket)
    
    async def broadcast_to_restaurant(self, restaurant_id: int, message: dict):
        """Broadcast message to all connections for a specific restaurant"""
        if restaurant_id in self.active_connections:
            message_str = json.dumps(message)
            disconnected = []
            
            for connection in self.active_connections[restaurant_id]:
                try:
                    await connection.send_text(message_str)
                except:
                    disconnected.append(connection)
            
            # Remove disconnected connections
            for connection in disconnected:
                self.disconnect(connection)
    
    async def broadcast_to_role(self, role: str, message: dict):
        """Broadcast message to all connections with a specific role"""
        if role in self.connections_by_role:
            message_str = json.dumps(message)
            disconnected = []
            
            for connection in self.connections_by_role[role]:
                try:
                    await connection.send_text(message_str)
                except:
                    disconnected.append(connection)
            
            # Remove disconnected connections
            for connection in disconnected:
                self.disconnect(connection)
    
    async def broadcast_order_update(self, restaurant_id: int, order_data: dict):
        """Broadcast order updates to relevant parties"""
        message = {
            "type": "order_update",
            "data": order_data,
            "timestamp": datetime.now().isoformat()
        }
        
        # Send to all restaurant connections
        await self.broadcast_to_restaurant(restaurant_id, message)
        
        # Send specifically to kitchen and waiters
        await self.broadcast_to_role("kitchen", message)
        await self.broadcast_to_role("waiter", message)
    
    async def broadcast_service_request(self, restaurant_id: int, request_data: dict):
        """Broadcast service requests to staff"""
        message = {
            "type": "service_request",
            "data": request_data,
            "timestamp": datetime.now().isoformat()
        }
        
        # Send to waiters and admin
        await self.broadcast_to_role("waiter", message)
        await self.broadcast_to_role("admin", message)
    
    async def broadcast_payment_update(self, restaurant_id: int, payment_data: dict):
        """Broadcast payment updates"""
        message = {
            "type": "payment_update",
            "data": payment_data,
            "timestamp": datetime.now().isoformat()
        }
        
        await self.broadcast_to_restaurant(restaurant_id, message)
    
    async def broadcast_table_status(self, restaurant_id: int, table_data: dict):
        """Broadcast table status updates"""
        message = {
            "type": "table_status_update",
            "data": table_data,
            "timestamp": datetime.now().isoformat()
        }
        
        await self.broadcast_to_restaurant(restaurant_id, message)
        await self.broadcast_to_role("waiter", message)
    
    def get_connection_stats(self):
        """Get connection statistics"""
        return {
            "total_restaurants": len(self.active_connections),
            "connections_by_restaurant": {
                str(restaurant_id): len(connections) 
                for restaurant_id, connections in self.active_connections.items()
            },
            "connections_by_role": {
                role: len(connections) 
                for role, connections in self.connections_by_role.items()
            },
            "total_connections": sum(
                len(connections) for connections in self.active_connections.values()
            ),
            "active_users": len(self.connection_info)
        }
    
    def get_restaurant_connections(self, restaurant_id: int) -> int:
        """Get number of active connections for a restaurant"""
        return len(self.active_connections.get(restaurant_id, []))
    
    def get_role_connections(self, role: str) -> int:
        """Get number of active connections for a role"""
        return len(self.connections_by_role.get(role, []))

# Global connection manager instance
connection_manager = ConnectionManager()

