from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from typing import List, Optional
from datetime import datetime
import os
from supabase import create_client, Client
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, messaging
import json

# Initialize FastAPI
app = FastAPI(title="Restaurant Ordering System", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "your-supabase-url")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "your-supabase-anon-key")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Firebase configuration
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate("firebase-service-account.json")
        firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Firebase initialization error: {e}")

# Pydantic models
class MenuItem(BaseModel):
    id: Optional[int] = None
    name: str
    description: str
    price: float
    category: str
    image_url: Optional[str] = None
    available: bool = True

class OrderItem(BaseModel):
    menu_item_id: int
    quantity: int
    special_instructions: Optional[str] = None

class Order(BaseModel):
    id: Optional[int] = None
    table_number: int
    items: List[OrderItem]
    status: str = "pending"
    total_amount: float
    customer_name: Optional[str] = None
    special_instructions: Optional[str] = None
    created_at: Optional[datetime] = None

class Table(BaseModel):
    id: Optional[int] = None
    table_number: int
    waiter_id: Optional[int] = None
    status: str = "available"  # available, occupied, reserved

class WaiterAlert(BaseModel):
    table_number: int
    message: str
    alert_type: str = "customer_request"

class PaymentRequest(BaseModel):
    order_id: int
    amount: float
    payment_method: str  # stripe, mpesa, cash

# Helper functions
def send_firebase_notification(token: str, title: str, body: str, data: dict = None):
    """Send Firebase Cloud Messaging notification"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )
        response = messaging.send(message)
        return {"success": True, "message_id": response}
    except Exception as e:
        return {"success": False, "error": str(e)}

def broadcast_to_role(role: str, title: str, body: str, data: dict = None):
    """Broadcast notification to all users with specific role"""
    try:
        # Get FCM tokens for users with specific role
        result = supabase.table("user_tokens").select("*").eq("role", role).execute()
        tokens = [row["fcm_token"] for row in result.data if row["fcm_token"]]
        
        if tokens:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                tokens=tokens,
            )
            response = messaging.send_multicast(message)
            return {"success": True, "success_count": response.success_count}
    except Exception as e:
        return {"success": False, "error": str(e)}

# Menu endpoints
@app.get("/api/menu", response_model=List[MenuItem])
async def get_menu():
    """Get all menu items"""
    try:
        result = supabase.table("menu_items").select("*").eq("available", True).execute()
        return result.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/menu/categories")
async def get_menu_categories():
    """Get all menu categories"""
    try:
        result = supabase.table("menu_items").select("category").execute()
        categories = list(set([item["category"] for item in result.data]))
        return {"categories": categories}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/menu/category/{category}")
async def get_menu_by_category(category: str):
    """Get menu items by category"""
    try:
        result = supabase.table("menu_items").select("*").eq("category", category).eq("available", True).execute()
        return result.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/menu", response_model=MenuItem)
async def create_menu_item(item: MenuItem):
    """Create new menu item (Admin only)"""
    try:
        result = supabase.table("menu_items").insert(item.dict(exclude={"id"})).execute()
        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/menu/{item_id}", response_model=MenuItem)
async def update_menu_item(item_id: int, item: MenuItem):
    """Update menu item (Admin only)"""
    try:
        result = supabase.table("menu_items").update(item.dict(exclude={"id"})).eq("id", item_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Menu item not found")
        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/menu/{item_id}")
async def delete_menu_item(item_id: int):
    """Delete menu item (Admin only)"""
    try:
        result = supabase.table("menu_items").delete().eq("id", item_id).execute()
        return {"message": "Menu item deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Order endpoints
@app.post("/api/orders", response_model=Order)
async def create_order(order: Order):
    """Create new order"""
    try:
        # Insert order
        order_data = {
            "table_number": order.table_number,
            "status": order.status,
            "total_amount": order.total_amount,
            "customer_name": order.customer_name,
            "special_instructions": order.special_instructions,
            "created_at": datetime.now().isoformat()
        }
        
        result = supabase.table("orders").insert(order_data).execute()
        order_id = result.data[0]["id"]
        
        # Insert order items
        for item in order.items:
            item_data = {
                "order_id": order_id,
                "menu_item_id": item.menu_item_id,
                "quantity": item.quantity,
                "special_instructions": item.special_instructions
            }
            supabase.table("order_items").insert(item_data).execute()
        
        # Update table status
        supabase.table("tables").update({"status": "occupied"}).eq("table_number", order.table_number).execute()
        
        # Send notification to kitchen
        broadcast_to_role("kitchen", "New Order", f"New order from Table {order.table_number}", 
                         {"order_id": str(order_id), "table_number": str(order.table_number)})
        
        return {**result.data[0], "items": order.items}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/orders")
async def get_orders(status: Optional[str] = None, table_number: Optional[int] = None):
    """Get orders with optional filters"""
    try:
        query = supabase.table("orders").select("*, order_items(*, menu_items(name, price))")
        
        if status:
            query = query.eq("status", status)
        if table_number:
            query = query.eq("table_number", table_number)
            
        result = query.order("created_at", desc=True).execute()
        return result.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/orders/{order_id}")
async def get_order(order_id: int):
    """Get specific order"""
    try:
        result = supabase.table("orders").select("*, order_items(*, menu_items(name, price))").eq("id", order_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Order not found")
        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/orders/{order_id}/status")
async def update_order_status(order_id: int, status: dict):
    """Update order status"""
    try:
        new_status = status.get("status")
        result = supabase.table("orders").update({"status": new_status}).eq("id", order_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Order not found")
        
        order = result.data[0]
        
        # Send notification based on status
        if new_status == "ready":
            # Get waiter for this table
            table_result = supabase.table("tables").select("waiter_id").eq("table_number", order["table_number"]).execute()
            if table_result.data and table_result.data[0]["waiter_id"]:
                waiter_tokens = supabase.table("user_tokens").select("fcm_token").eq("user_id", table_result.data[0]["waiter_id"]).execute()
                if waiter_tokens.data:
                    for token_data in waiter_tokens.data:
                        send_firebase_notification(
                            token_data["fcm_token"],
                            "Order Ready",
                            f"Order #{order_id} for Table {order['table_number']} is ready",
                            {"order_id": str(order_id), "table_number": str(order["table_number"])}
                        )
        
        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Table endpoints
@app.get("/api/tables")
async def get_tables():
    """Get all tables"""
    try:
        result = supabase.table("tables").select("*").execute()
        return result.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/tables", response_model=Table)
async def create_table(table: Table):
    """Create new table"""
    try:
        result = supabase.table("tables").insert(table.dict(exclude={"id"})).execute()
        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/tables/{table_id}")
async def update_table(table_id: int, table: Table):
    """Update table"""
    try:
        result = supabase.table("tables").update(table.dict(exclude={"id"})).eq("id", table_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Table not found")
        return result.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/tables/{table_number}/assign-waiter")
async def assign_waiter_to_table(table_number: int, waiter_data: dict):
    """Assign waiter to table"""
    try:
        waiter_id = waiter_data.get("waiter_id")
        result = supabase.table("tables").update({"waiter_id": waiter_id}).eq("table_number", table_number).execute()
        return {"message": "Waiter assigned successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Waiter alert endpoints
@app.post("/api/waiter-alerts")
async def send_waiter_alert(alert: WaiterAlert):
    """Send alert to waiter"""
    try:
        # Get waiter assigned to table
        table_result = supabase.table("tables").select("waiter_id").eq("table_number", alert.table_number).execute()
        
        if not table_result.data or not table_result.data[0]["waiter_id"]:
            # Broadcast to all waiters if no specific waiter assigned
            broadcast_to_role("waiter", "Customer Request", f"Table {alert.table_number}: {alert.message}")
        else:
            waiter_id = table_result.data[0]["waiter_id"]
            # Send to specific waiter
            waiter_tokens = supabase.table("user_tokens").select("fcm_token").eq("user_id", waiter_id).execute()
            if waiter_tokens.data:
                for token_data in waiter_tokens.data:
                    send_firebase_notification(
                        token_data["fcm_token"],
                        "Customer Request",
                        f"Table {alert.table_number}: {alert.message}",
                        {"table_number": str(alert.table_number), "alert_type": alert.alert_type}
                    )
        
        # Store alert in database
        alert_data = {
            "table_number": alert.table_number,
            "message": alert.message,
            "alert_type": alert.alert_type,
            "created_at": datetime.now().isoformat(),
            "status": "sent"
        }
        supabase.table("waiter_alerts").insert(alert_data).execute()
        
        return {"message": "Alert sent successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/waiter-alerts")
async def get_waiter_alerts(waiter_id: Optional[int] = None):
    """Get waiter alerts"""
    try:
        if waiter_id:
            # Get alerts for tables assigned to specific waiter
            tables_result = supabase.table("tables").select("table_number").eq("waiter_id", waiter_id).execute()
            table_numbers = [t["table_number"] for t in tables_result.data]
            
            if table_numbers:
                result = supabase.table("waiter_alerts").select("*").in_("table_number", table_numbers).order("created_at", desc=True).execute()
            else:
                result = {"data": []}
        else:
            result = supabase.table("waiter_alerts").select("*").order("created_at", desc=True).execute()
        
        return result.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Payment endpoints
@app.post("/api/payments")
async def process_payment(payment: PaymentRequest):
    """Process payment (mock implementation)"""
    try:
        # Mock payment processing
        payment_data = {
            "order_id": payment.order_id,
            "amount": payment.amount,
            "payment_method": payment.payment_method,
            "status": "completed",  # Mock success
            "transaction_id": f"txn_{payment.order_id}_{datetime.now().timestamp()}",
            "created_at": datetime.now().isoformat()
        }
        
        result = supabase.table("payments").insert(payment_data).execute()
        
        # Update order status to paid
        supabase.table("orders").update({"payment_status": "paid"}).eq("id", payment.order_id).execute()
        
        return {"message": "Payment processed successfully", "transaction_id": payment_data["transaction_id"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Analytics endpoints
@app.get("/api/analytics/daily-sales")
async def get_daily_sales():
    """Get daily sales report"""
    try:
        today = datetime.now().date().isoformat()
        result = supabase.table("orders").select("total_amount, created_at").gte("created_at", today).execute()
        
        total_sales = sum([order["total_amount"] for order in result.data])
        total_orders = len(result.data)
        
        return {
            "date": today,
            "total_sales": total_sales,
            "total_orders": total_orders,
            "average_order_value": total_sales / total_orders if total_orders > 0 else 0
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/analytics/popular-items")
async def get_popular_items():
    """Get popular menu items"""
    try:
        # This would require a more complex query in production
        result = supabase.table("order_items").select("menu_item_id, quantity, menu_items(name)").execute()
        
        item_counts = {}
        for item in result.data:
            menu_item_id = item["menu_item_id"]
            if menu_item_id not in item_counts:
                item_counts[menu_item_id] = {
                    "name": item["menu_items"]["name"],
                    "total_quantity": 0
                }
            item_counts[menu_item_id]["total_quantity"] += item["quantity"]
        
        # Sort by popularity
        popular_items = sorted(item_counts.values(), key=lambda x: x["total_quantity"], reverse=True)[:10]
        
        return {"popular_items": popular_items}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# FCM token management
@app.post("/api/fcm-token")
async def register_fcm_token(token_data: dict):
    """Register FCM token for user"""
    try:
        result = supabase.table("user_tokens").upsert({
            "user_id": token_data.get("user_id"),
            "fcm_token": token_data.get("fcm_token"),
            "role": token_data.get("role"),
            "device_id": token_data.get("device_id")
        }).execute()
        return {"message": "FCM token registered successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

