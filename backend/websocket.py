from fastapi import WebSocket, WebSocketDisconnect, Query, Depends
from sqlalchemy.orm import Session
import json
from typing import Optional
from connection_manager import manager
from database import get_db
import models
import auth

async def websocket_endpoint(
    websocket: WebSocket,
    restaurant_id: int = Query(...),
    user_id: Optional[int] = Query(None),
    user_role: str = Query("customer"),
    token: Optional[str] = Query(None)
):
    """WebSocket endpoint for real-time communication"""
    
    # Authenticate user if token provided
    authenticated_user = None
    if token:
        try:
            # Create a mock session for database operations
            db = next(get_db())
            
            # Verify token
            payload = auth.verify_token(token)
            if payload:
                user_id_from_token = payload.get("sub")
                if user_id_from_token:
                    authenticated_user = auth.get_user_by_id(db, int(user_id_from_token))
                    if authenticated_user:
                        user_id = authenticated_user.id
                        user_role = authenticated_user.role.value
            
            db.close()
        except Exception as e:
            print(f"WebSocket authentication error: {e}")
    
    await manager.connect(websocket, restaurant_id, user_id, user_role)
    
    try:
        # Send welcome message
        welcome_message = {
            "type": "connection_established",
            "data": {
                "restaurant_id": restaurant_id,
                "user_id": user_id,
                "user_role": user_role,
                "authenticated": authenticated_user is not None
            }
        }
        await manager.send_personal_message(welcome_message, websocket)
        
        # Listen for messages
        while True:
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                await handle_websocket_message(websocket, message, restaurant_id, user_id, user_role)
            except json.JSONDecodeError:
                error_message = {
                    "type": "error",
                    "data": {"message": "Invalid JSON format"}
                }
                await manager.send_personal_message(error_message, websocket)
            except Exception as e:
                error_message = {
                    "type": "error",
                    "data": {"message": f"Error processing message: {str(e)}"}
                }
                await manager.send_personal_message(error_message, websocket)
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f"WebSocket error: {e}")
        manager.disconnect(websocket)

async def handle_websocket_message(websocket: WebSocket, message: dict, restaurant_id: int, user_id: int, user_role: str):
    """Handle incoming WebSocket messages"""
    
    message_type = message.get("type")
    data = message.get("data", {})
    
    if message_type == "ping":
        # Respond to ping with pong
        pong_message = {
            "type": "pong",
            "data": {"timestamp": data.get("timestamp")}
        }
        await manager.send_personal_message(pong_message, websocket)
    
    elif message_type == "join_room":
        # Join a specific room (e.g., kitchen, admin)
        room = data.get("room")
        if room and user_role in ["kitchen", "waiter", "admin"]:
            # Update connection metadata
            connection_info = manager.get_connection_info(websocket)
            connection_info["room"] = room
            
            join_message = {
                "type": "room_joined",
                "data": {"room": room}
            }
            await manager.send_personal_message(join_message, websocket)
    
    elif message_type == "order_status_request":
        # Request order status update
        order_id = data.get("order_id")
        if order_id and user_id:
            # This would typically fetch from database and send update
            status_message = {
                "type": "order_status_update",
                "data": {
                    "order_id": order_id,
                    "status": "in_progress",  # This should come from database
                    "estimated_time": 15
                }
            }
            await manager.send_personal_message(status_message, websocket)
    
    elif message_type == "kitchen_notification":
        # Send notification to kitchen staff
        if user_role in ["admin", "waiter"]:
            kitchen_message = {
                "type": "kitchen_alert",
                "data": data
            }
            await manager.broadcast_to_role(restaurant_id, "kitchen", kitchen_message)
    
    elif message_type == "service_request_update":
        # Update service request status
        if user_role in ["waiter", "admin"]:
            update_message = {
                "type": "service_request_updated",
                "data": data
            }
            # Broadcast to all staff
            await manager.broadcast_to_role(restaurant_id, "waiter", update_message)
            await manager.broadcast_to_role(restaurant_id, "admin", update_message)
    
    elif message_type == "broadcast_announcement":
        # Admin broadcast to all users
        if user_role == "admin":
            announcement = {
                "type": "announcement",
                "data": data
            }
            await manager.broadcast_to_restaurant(restaurant_id, announcement)
    
    elif message_type == "get_connection_stats":
        # Get connection statistics (admin only)
        if user_role == "admin":
            stats = {
                "type": "connection_stats",
                "data": {
                    "restaurant_connections": manager.get_restaurant_connections_count(restaurant_id),
                    "all_connections": manager.get_all_connections_info()
                }
            }
            await manager.send_personal_message(stats, websocket)
    
    else:
        # Unknown message type
        error_message = {
            "type": "error",
            "data": {"message": f"Unknown message type: {message_type}"}
        }
        await manager.send_personal_message(error_message, websocket)

