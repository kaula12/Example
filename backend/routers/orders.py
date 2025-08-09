from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
import uuid

from database import get_db
from models.order import Order, OrderItem, ServiceRequest
from models.menu import MenuItem
from models.restaurant import Table
from models.user import User
from routers.auth import get_current_active_user

router = APIRouter()

# Pydantic models
class OrderItemCreate(BaseModel):
    menu_item_id: int
    quantity: int
    customizations: Optional[dict] = None
    special_instructions: Optional[str] = None

class OrderCreate(BaseModel):
    table_qr_code: str
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_email: Optional[str] = None
    items: List[OrderItemCreate]
    special_instructions: Optional[str] = None

class OrderItemResponse(BaseModel):
    id: int
    menu_item_id: int
    menu_item_name: str
    quantity: int
    unit_price: float
    total_price: float
    customizations: Optional[dict]
    special_instructions: Optional[str]
    status: str
    
    class Config:
        from_attributes = True

class OrderResponse(BaseModel):
    id: int
    order_number: str
    table_number: str
    status: str
    subtotal: float
    tax_amount: float
    service_charge: float
    discount_amount: float
    total_amount: float
    payment_method: Optional[str]
    payment_status: str
    customer_name: Optional[str]
    customer_phone: Optional[str]
    special_instructions: Optional[str]
    estimated_preparation_time: Optional[int]
    created_at: datetime
    items: List[OrderItemResponse] = []
    
    class Config:
        from_attributes = True

class OrderStatusUpdate(BaseModel):
    status: str  # pending, confirmed, preparing, ready, served, cancelled

class ServiceRequestCreate(BaseModel):
    table_qr_code: str
    request_type: str  # water, bill, assistance, cleanup
    message: Optional[str] = None
    priority: int = 1  # 1=low, 2=medium, 3=high, 4=urgent

class ServiceRequestResponse(BaseModel):
    id: int
    table_number: str
    request_type: str
    message: Optional[str]
    priority: int
    status: str
    created_at: datetime
    acknowledged_at: Optional[datetime]
    completed_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# Utility functions
def calculate_order_totals(items: List[OrderItem]) -> dict:
    """Calculate order totals"""
    subtotal = sum(item.total_price for item in items)
    tax_rate = 0.16  # 16% VAT
    service_charge_rate = 0.10  # 10% service charge
    
    tax_amount = subtotal * tax_rate
    service_charge = subtotal * service_charge_rate
    total_amount = subtotal + tax_amount + service_charge
    
    return {
        "subtotal": round(subtotal, 2),
        "tax_amount": round(tax_amount, 2),
        "service_charge": round(service_charge, 2),
        "total_amount": round(total_amount, 2)
    }

def generate_order_number() -> str:
    """Generate unique order number"""
    date_str = datetime.now().strftime("%Y%m%d")
    unique_id = str(uuid.uuid4())[:8].upper()
    return f"ORD-{date_str}-{unique_id}"

# Routes
@router.post("/", response_model=OrderResponse)
async def create_order(
    order_data: OrderCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_active_user)
):
    """Create a new order"""
    # Find table by QR code
    table = db.query(Table).filter(Table.qr_code == order_data.table_qr_code).first()
    if not table:
        raise HTTPException(status_code=404, detail="Invalid QR code")
    
    if not table.is_active:
        raise HTTPException(status_code=400, detail="Table is not active")
    
    # Validate menu items and calculate prices
    order_items_data = []
    total_prep_time = 0
    
    for item_data in order_data.items:
        menu_item = db.query(MenuItem).filter(MenuItem.id == item_data.menu_item_id).first()
        if not menu_item:
            raise HTTPException(status_code=404, detail=f"Menu item {item_data.menu_item_id} not found")
        
        if not menu_item.is_available:
            raise HTTPException(status_code=400, detail=f"Menu item '{menu_item.name}' is not available")
        
        # Calculate item total price (including customizations)
        unit_price = menu_item.price
        # TODO: Add customization price calculations
        total_price = unit_price * item_data.quantity
        
        order_items_data.append({
            "menu_item": menu_item,
            "quantity": item_data.quantity,
            "unit_price": unit_price,
            "total_price": total_price,
            "customizations": item_data.customizations,
            "special_instructions": item_data.special_instructions
        })
        
        total_prep_time = max(total_prep_time, menu_item.preparation_time)
    
    # Create order
    order = Order(
        restaurant_id=table.restaurant_id,
        table_id=table.id,
        customer_id=current_user.id if current_user else None,
        order_number=generate_order_number(),
        status="pending",
        subtotal=0,  # Will be calculated below
        tax_amount=0,
        service_charge=0,
        discount_amount=0,
        total_amount=0,
        payment_status="pending",
        customer_name=order_data.customer_name or (current_user.full_name if current_user else None),
        customer_phone=order_data.customer_phone or (current_user.phone if current_user else None),
        customer_email=order_data.customer_email or (current_user.email if current_user else None),
        special_instructions=order_data.special_instructions,
        estimated_preparation_time=total_prep_time
    )
    
    db.add(order)
    db.commit()
    db.refresh(order)
    
    # Create order items
    order_items = []
    for item_data in order_items_data:
        order_item = OrderItem(
            order_id=order.id,
            menu_item_id=item_data["menu_item"].id,
            quantity=item_data["quantity"],
            unit_price=item_data["unit_price"],
            total_price=item_data["total_price"],
            customizations=item_data["customizations"],
            special_instructions=item_data["special_instructions"],
            status="pending"
        )
        db.add(order_item)
        order_items.append(order_item)
    
    db.commit()
    
    # Calculate and update order totals
    totals = calculate_order_totals(order_items)
    order.subtotal = totals["subtotal"]
    order.tax_amount = totals["tax_amount"]
    order.service_charge = totals["service_charge"]
    order.total_amount = totals["total_amount"]
    
    db.commit()
    db.refresh(order)
    
    # Load order items with menu item names for response
    order_items_response = []
    for item in order_items:
        item_response = OrderItemResponse(
            id=item.id,
            menu_item_id=item.menu_item_id,
            menu_item_name=item.menu_item.name,
            quantity=item.quantity,
            unit_price=item.unit_price,
            total_price=item.total_price,
            customizations=item.customizations,
            special_instructions=item.special_instructions,
            status=item.status
        )
        order_items_response.append(item_response)
    
    # Create response
    response = OrderResponse(
        id=order.id,
        order_number=order.order_number,
        table_number=table.table_number,
        status=order.status,
        subtotal=order.subtotal,
        tax_amount=order.tax_amount,
        service_charge=order.service_charge,
        discount_amount=order.discount_amount,
        total_amount=order.total_amount,
        payment_method=order.payment_method,
        payment_status=order.payment_status,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        special_instructions=order.special_instructions,
        estimated_preparation_time=order.estimated_preparation_time,
        created_at=order.created_at,
        items=order_items_response
    )
    
    return response

@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get order details"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Check permissions
    if current_user.role not in ["admin", "waiter", "kitchen"] and order.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this order")
    
    # Load order items
    order_items = db.query(OrderItem).filter(OrderItem.order_id == order_id).all()
    items_response = []
    
    for item in order_items:
        item_response = OrderItemResponse(
            id=item.id,
            menu_item_id=item.menu_item_id,
            menu_item_name=item.menu_item.name,
            quantity=item.quantity,
            unit_price=item.unit_price,
            total_price=item.total_price,
            customizations=item.customizations,
            special_instructions=item.special_instructions,
            status=item.status
        )
        items_response.append(item_response)
    
    response = OrderResponse(
        id=order.id,
        order_number=order.order_number,
        table_number=order.table.table_number,
        status=order.status,
        subtotal=order.subtotal,
        tax_amount=order.tax_amount,
        service_charge=order.service_charge,
        discount_amount=order.discount_amount,
        total_amount=order.total_amount,
        payment_method=order.payment_method,
        payment_status=order.payment_status,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        special_instructions=order.special_instructions,
        estimated_preparation_time=order.estimated_preparation_time,
        created_at=order.created_at,
        items=items_response
    )
    
    return response

@router.put("/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: int,
    status_update: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update order status (staff only)"""
    if current_user.role not in ["admin", "waiter", "kitchen"]:
        raise HTTPException(status_code=403, detail="Not authorized to update order status")
    
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Update status and timestamps
    old_status = order.status
    order.status = status_update.status
    
    if status_update.status == "preparing" and old_status != "preparing":
        order.preparation_started_at = datetime.utcnow()
    elif status_update.status == "ready" and old_status != "ready":
        order.ready_at = datetime.utcnow()
    elif status_update.status == "served" and old_status != "served":
        order.served_at = datetime.utcnow()
    
    db.commit()
    
    # Return updated order
    return await get_order(order_id, db, current_user)

@router.get("/", response_model=List[OrderResponse])
async def get_orders(
    status: Optional[str] = None,
    table_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get orders with filters"""
    query = db.query(Order)
    
    # Filter by user role
    if current_user.role == "customer":
        query = query.filter(Order.customer_id == current_user.id)
    elif current_user.role in ["waiter", "kitchen"]:
        # Staff can see all orders for their restaurant
        # TODO: Add restaurant filtering based on staff assignment
        pass
    
    # Apply filters
    if status:
        query = query.filter(Order.status == status)
    
    if table_id:
        query = query.filter(Order.table_id == table_id)
    
    orders = query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()
    
    # Convert to response format
    orders_response = []
    for order in orders:
        items_response = []
        for item in order.order_items:
            item_response = OrderItemResponse(
                id=item.id,
                menu_item_id=item.menu_item_id,
                menu_item_name=item.menu_item.name,
                quantity=item.quantity,
                unit_price=item.unit_price,
                total_price=item.total_price,
                customizations=item.customizations,
                special_instructions=item.special_instructions,
                status=item.status
            )
            items_response.append(item_response)
        
        order_response = OrderResponse(
            id=order.id,
            order_number=order.order_number,
            table_number=order.table.table_number,
            status=order.status,
            subtotal=order.subtotal,
            tax_amount=order.tax_amount,
            service_charge=order.service_charge,
            discount_amount=order.discount_amount,
            total_amount=order.total_amount,
            payment_method=order.payment_method,
            payment_status=order.payment_status,
            customer_name=order.customer_name,
            customer_phone=order.customer_phone,
            special_instructions=order.special_instructions,
            estimated_preparation_time=order.estimated_preparation_time,
            created_at=order.created_at,
            items=items_response
        )
        orders_response.append(order_response)
    
    return orders_response

# Service Requests
@router.post("/service-requests", response_model=ServiceRequestResponse)
async def create_service_request(
    request_data: ServiceRequestCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_active_user)
):
    """Create a service request"""
    # Find table by QR code
    table = db.query(Table).filter(Table.qr_code == request_data.table_qr_code).first()
    if not table:
        raise HTTPException(status_code=404, detail="Invalid QR code")
    
    service_request = ServiceRequest(
        table_id=table.id,
        customer_id=current_user.id if current_user else None,
        request_type=request_data.request_type,
        message=request_data.message,
        priority=request_data.priority,
        status="pending"
    )
    
    db.add(service_request)
    db.commit()
    db.refresh(service_request)
    
    response = ServiceRequestResponse(
        id=service_request.id,
        table_number=table.table_number,
        request_type=service_request.request_type,
        message=service_request.message,
        priority=service_request.priority,
        status=service_request.status,
        created_at=service_request.created_at,
        acknowledged_at=service_request.acknowledged_at,
        completed_at=service_request.completed_at
    )
    
    return response

@router.get("/service-requests", response_model=List[ServiceRequestResponse])
async def get_service_requests(
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get service requests"""
    query = db.query(ServiceRequest)
    
    # Filter by user role
    if current_user.role == "customer":
        query = query.filter(ServiceRequest.customer_id == current_user.id)
    
    if status:
        query = query.filter(ServiceRequest.status == status)
    
    requests = query.order_by(ServiceRequest.created_at.desc()).offset(skip).limit(limit).all()
    
    requests_response = []
    for req in requests:
        response = ServiceRequestResponse(
            id=req.id,
            table_number=req.table.table_number,
            request_type=req.request_type,
            message=req.message,
            priority=req.priority,
            status=req.status,
            created_at=req.created_at,
            acknowledged_at=req.acknowledged_at,
            completed_at=req.completed_at
        )
        requests_response.append(response)
    
    return requests_response

