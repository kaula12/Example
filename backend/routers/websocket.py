from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import List, Dict
import json
from datetime import datetime

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        # Store connections by restaurant_id
        self.active_connections: Dict[int, List[WebSocket]] = {}
        # Store connections by user role for targeted messaging
        self.connections_by_role: Dict[str, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, restaurant_id: int, user_role: str = None):
        await websocket.accept()
        
        # Add to restaurant connections
        if restaurant_id not in self.active_connections:
            self.active_connections[restaurant_id] = []
        self.active_connections[restaurant_id].append(websocket)
        
        # Add to role-based connections
        if user_role:
            if user_role not in self.connections_by_role:
                self.connections_by_role[user_role] = []
            self.connections_by_role[user_role].append(websocket)
    
    def disconnect(self, websocket: WebSocket, restaurant_id: int, user_role: str = None):
        # Remove from restaurant connections
        if restaurant_id in self.active_connections:
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
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)
    
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
                self.active_connections[restaurant_id].remove(connection)
    
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
                self.connections_by_role[role].remove(connection)
    
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

# Global connection manager instance
manager = ConnectionManager()

@router.websocket("/connect/{restaurant_id}")
async def websocket_endpoint(websocket: WebSocket, restaurant_id: int, user_role: str = None):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, restaurant_id, user_role)
    
    try:
        # Send welcome message
        welcome_message = {
            "type": "connection_established",
            "message": f"Connected to restaurant {restaurant_id}",
            "timestamp": datetime.now().isoformat()
        }
        await websocket.send_text(json.dumps(welcome_message))
        
        while True:
            # Listen for incoming messages
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                message_type = message.get("type")
                
                if message_type == "ping":
                    # Respond to ping with pong
                    pong_message = {
                        "type": "pong",
                        "timestamp": datetime.now().isoformat()
                    }
                    await websocket.send_text(json.dumps(pong_message))
                
                elif message_type == "order_status_update":
                    # Broadcast order status update
                    await manager.broadcast_order_update(restaurant_id, message.get("data", {}))
                
                elif message_type == "service_request":
                    # Broadcast service request
                    await manager.broadcast_service_request(restaurant_id, message.get("data", {}))
                
                elif message_type == "payment_update":
                    # Broadcast payment update
                    await manager.broadcast_payment_update(restaurant_id, message.get("data", {}))
                
                else:
                    # Echo unknown messages back
                    echo_message = {
                        "type": "echo",
                        "original_message": message,
                        "timestamp": datetime.now().isoformat()
                    }
                    await websocket.send_text(json.dumps(echo_message))
                    
            except json.JSONDecodeError:
                # Handle invalid JSON
                error_message = {
                    "type": "error",
                    "message": "Invalid JSON format",
                    "timestamp": datetime.now().isoformat()
                }
                await websocket.send_text(json.dumps(error_message))
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, restaurant_id, user_role)

@router.get("/connections/stats")
async def get_connection_stats():
    """Get WebSocket connection statistics (for debugging)"""
    stats = {
        "total_restaurants": len(manager.active_connections),
        "connections_by_restaurant": {
            str(restaurant_id): len(connections) 
            for restaurant_id, connections in manager.active_connections.items()
        },
        "connections_by_role": {
            role: len(connections) 
            for role, connections in manager.connections_by_role.items()
        },
        "total_connections": sum(
            len(connections) for connections in manager.active_connections.values()
        )
    }
    return stats

# Helper functions for other routers to use
async def notify_order_update(restaurant_id: int, order_data: dict):
    """Helper function to notify about order updates"""
    await manager.broadcast_order_update(restaurant_id, order_data)

async def notify_service_request(restaurant_id: int, request_data: dict):
    """Helper function to notify about service requests"""
    await manager.broadcast_service_request(restaurant_id, request_data)

async def notify_payment_update(restaurant_id: int, payment_data: dict):
    """Helper function to notify about payment updates"""
    await manager.broadcast_payment_update(restaurant_id, payment_data)

