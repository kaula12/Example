from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel

from database import get_db
from models.user import User
from models.restaurant import Restaurant, Table
from models.menu import Category, MenuItem
from models.order import Order, OrderItem
from models.payment import Payment
from routers.auth import get_current_active_user

router = APIRouter()

# Pydantic models
class RestaurantCreate(BaseModel):
    name: str
    description: Optional[str] = None
    address: str
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None

class RestaurantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    is_active: Optional[bool] = None

class TableCreate(BaseModel):
    table_number: str
    capacity: int = 4
    location: Optional[str] = None

class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: int = 0

class MenuItemCreate(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    price: float
    image_url: Optional[str] = None
    is_vegetarian: bool = False
    is_vegan: bool = False
    is_gluten_free: bool = False
    preparation_time: int = 15
    customization_options: Optional[dict] = None

class MenuItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    image_url: Optional[str] = None
    is_available: Optional[bool] = None
    preparation_time: Optional[int] = None

class SalesAnalytics(BaseModel):
    total_orders: int
    total_revenue: float
    average_order_value: float
    top_selling_items: List[dict]
    orders_by_status: dict
    revenue_by_day: List[dict]

# Utility functions
def require_admin_or_staff(current_user: User):
    """Check if user has admin or staff permissions"""
    if current_user.role not in ["admin", "waiter", "kitchen"]:
        raise HTTPException(status_code=403, detail="Admin or staff access required")

def require_admin(current_user: User):
    """Check if user has admin permissions"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")

# Restaurant Management
@router.post("/restaurants", response_model=dict)
async def create_restaurant(
    restaurant_data: RestaurantCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new restaurant (admin only)"""
    require_admin(current_user)
    
    restaurant = Restaurant(
        name=restaurant_data.name,
        description=restaurant_data.description,
        address=restaurant_data.address,
        phone=restaurant_data.phone,
        email=restaurant_data.email,
        website=restaurant_data.website,
        is_active=True
    )
    
    db.add(restaurant)
    db.commit()
    db.refresh(restaurant)
    
    return {"message": "Restaurant created successfully", "restaurant_id": restaurant.id}

@router.put("/restaurants/{restaurant_id}")
async def update_restaurant(
    restaurant_id: int,
    restaurant_data: RestaurantUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update restaurant details (admin only)"""
    require_admin(current_user)
    
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    
    # Update fields
    for field, value in restaurant_data.dict(exclude_unset=True).items():
        setattr(restaurant, field, value)
    
    db.commit()
    return {"message": "Restaurant updated successfully"}

# Table Management
@router.post("/restaurants/{restaurant_id}/tables")
async def create_table(
    restaurant_id: int,
    table_data: TableCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new table (admin only)"""
    require_admin(current_user)
    
    # Check if restaurant exists
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    
    # Check if table number already exists
    existing_table = db.query(Table).filter(
        Table.restaurant_id == restaurant_id,
        Table.table_number == table_data.table_number
    ).first()
    
    if existing_table:
        raise HTTPException(status_code=400, detail="Table number already exists")
    
    # Generate QR code
    import uuid
    qr_code = f"QR_{restaurant_id}_{table_data.table_number}_{uuid.uuid4().hex[:8]}"
    
    table = Table(
        restaurant_id=restaurant_id,
        table_number=table_data.table_number,
        qr_code=qr_code,
        capacity=table_data.capacity,
        location=table_data.location,
        is_active=True
    )
    
    db.add(table)
    db.commit()
    db.refresh(table)
    
    return {
        "message": "Table created successfully",
        "table_id": table.id,
        "qr_code": table.qr_code
    }

@router.get("/restaurants/{restaurant_id}/tables")
async def get_restaurant_tables(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get all tables for a restaurant"""
    require_admin_or_staff(current_user)
    
    tables = db.query(Table).filter(Table.restaurant_id == restaurant_id).all()
    return tables

# Menu Management
@router.post("/restaurants/{restaurant_id}/categories")
async def create_category(
    restaurant_id: int,
    category_data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new menu category (admin only)"""
    require_admin(current_user)
    
    category = Category(
        restaurant_id=restaurant_id,
        name=category_data.name,
        description=category_data.description,
        image_url=category_data.image_url,
        sort_order=category_data.sort_order,
        is_active=True
    )
    
    db.add(category)
    db.commit()
    db.refresh(category)
    
    return {"message": "Category created successfully", "category_id": category.id}

@router.post("/menu-items")
async def create_menu_item(
    item_data: MenuItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new menu item (admin only)"""
    require_admin(current_user)
    
    # Check if category exists
    category = db.query(Category).filter(Category.id == item_data.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    menu_item = MenuItem(
        category_id=item_data.category_id,
        name=item_data.name,
        description=item_data.description,
        price=item_data.price,
        image_url=item_data.image_url,
        is_vegetarian=item_data.is_vegetarian,
        is_vegan=item_data.is_vegan,
        is_gluten_free=item_data.is_gluten_free,
        preparation_time=item_data.preparation_time,
        customization_options=item_data.customization_options,
        is_available=True
    )
    
    db.add(menu_item)
    db.commit()
    db.refresh(menu_item)
    
    return {"message": "Menu item created successfully", "item_id": menu_item.id}

@router.put("/menu-items/{item_id}")
async def update_menu_item(
    item_id: int,
    item_data: MenuItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update menu item (admin only)"""
    require_admin(current_user)
    
    menu_item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not menu_item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    
    # Update fields
    for field, value in item_data.dict(exclude_unset=True).items():
        setattr(menu_item, field, value)
    
    db.commit()
    return {"message": "Menu item updated successfully"}

@router.delete("/menu-items/{item_id}")
async def delete_menu_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Delete menu item (admin only)"""
    require_admin(current_user)
    
    menu_item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not menu_item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    
    # Soft delete - just mark as unavailable
    menu_item.is_available = False
    db.commit()
    
    return {"message": "Menu item deleted successfully"}

# Order Management
@router.get("/orders")
async def get_all_orders(
    status: Optional[str] = Query(None),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get all orders with filters (staff only)"""
    require_admin_or_staff(current_user)
    
    query = db.query(Order)
    
    if status:
        query = query.filter(Order.status == status)
    
    if date_from:
        query = query.filter(Order.created_at >= date_from)
    
    if date_to:
        query = query.filter(Order.created_at <= date_to)
    
    orders = query.order_by(desc(Order.created_at)).offset(skip).limit(limit).all()
    
    return {
        "orders": orders,
        "total": query.count()
    }

# Analytics
@router.get("/analytics/sales", response_model=SalesAnalytics)
async def get_sales_analytics(
    restaurant_id: Optional[int] = Query(None),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get sales analytics (admin/staff only)"""
    require_admin_or_staff(current_user)
    
    # Default to last 30 days if no date range provided
    if not date_from:
        date_from = datetime.now() - timedelta(days=30)
    if not date_to:
        date_to = datetime.now()
    
    # Base query
    query = db.query(Order).filter(
        Order.created_at >= date_from,
        Order.created_at <= date_to,
        Order.status != "cancelled"
    )
    
    if restaurant_id:
        query = query.filter(Order.restaurant_id == restaurant_id)
    
    orders = query.all()
    
    # Calculate metrics
    total_orders = len(orders)
    total_revenue = sum(order.total_amount for order in orders)
    average_order_value = total_revenue / total_orders if total_orders > 0 else 0
    
    # Orders by status
    orders_by_status = {}
    for order in orders:
        status = order.status
        orders_by_status[status] = orders_by_status.get(status, 0) + 1
    
    # Top selling items
    item_sales = {}
    for order in orders:
        for item in order.order_items:
            item_name = item.menu_item.name
            if item_name not in item_sales:
                item_sales[item_name] = {"quantity": 0, "revenue": 0}
            item_sales[item_name]["quantity"] += item.quantity
            item_sales[item_name]["revenue"] += item.total_price
    
    top_selling_items = sorted(
        [{"name": name, **stats} for name, stats in item_sales.items()],
        key=lambda x: x["quantity"],
        reverse=True
    )[:10]
    
    # Revenue by day
    revenue_by_day = {}
    for order in orders:
        day = order.created_at.date().isoformat()
        revenue_by_day[day] = revenue_by_day.get(day, 0) + order.total_amount
    
    revenue_by_day_list = [
        {"date": date, "revenue": revenue}
        for date, revenue in sorted(revenue_by_day.items())
    ]
    
    return SalesAnalytics(
        total_orders=total_orders,
        total_revenue=total_revenue,
        average_order_value=average_order_value,
        top_selling_items=top_selling_items,
        orders_by_status=orders_by_status,
        revenue_by_day=revenue_by_day_list
    )

@router.get("/analytics/dashboard")
async def get_dashboard_stats(
    restaurant_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get dashboard statistics (admin/staff only)"""
    require_admin_or_staff(current_user)
    
    # Today's stats
    today = datetime.now().date()
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())
    
    query = db.query(Order).filter(
        Order.created_at >= today_start,
        Order.created_at <= today_end
    )
    
    if restaurant_id:
        query = query.filter(Order.restaurant_id == restaurant_id)
    
    today_orders = query.all()
    
    # Current active orders
    active_orders = db.query(Order).filter(
        Order.status.in_(["pending", "confirmed", "preparing"])
    )
    
    if restaurant_id:
        active_orders = active_orders.filter(Order.restaurant_id == restaurant_id)
    
    active_orders_count = active_orders.count()
    
    # Pending service requests
    from models.order import ServiceRequest
    pending_requests = db.query(ServiceRequest).filter(
        ServiceRequest.status == "pending"
    ).count()
    
    return {
        "today_orders": len(today_orders),
        "today_revenue": sum(order.total_amount for order in today_orders),
        "active_orders": active_orders_count,
        "pending_service_requests": pending_requests,
        "average_order_value": sum(order.total_amount for order in today_orders) / len(today_orders) if today_orders else 0
    }

# User Management
@router.get("/users")
async def get_users(
    role: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get all users (admin only)"""
    require_admin(current_user)
    
    query = db.query(User)
    
    if role:
        query = query.filter(User.role == role)
    
    users = query.offset(skip).limit(limit).all()
    
    return {
        "users": users,
        "total": query.count()
    }

@router.put("/users/{user_id}/role")
async def update_user_role(
    user_id: int,
    role: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update user role (admin only)"""
    require_admin(current_user)
    
    if role not in ["customer", "waiter", "kitchen", "admin"]:
        raise HTTPException(status_code=400, detail="Invalid role")
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.role = role
    db.commit()
    
    return {"message": "User role updated successfully"}

