from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from models import UserRole, OrderStatus, PaymentStatus, PaymentMethod, ServiceRequestStatus

# Base schemas
class BaseSchema(BaseModel):
    class Config:
        from_attributes = True

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    role: UserRole = UserRole.CUSTOMER

class UserCreate(UserBase):
    password: Optional[str] = None
    supabase_id: Optional[str] = None

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None

class User(UserBase):
    id: int
    is_active: bool
    supabase_id: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Restaurant schemas
class RestaurantBase(BaseModel):
    name: str
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None

class RestaurantCreate(RestaurantBase):
    pass

class RestaurantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    is_active: Optional[bool] = None

class Restaurant(RestaurantBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Table schemas
class TableBase(BaseModel):
    table_number: str
    capacity: int = 4

class TableCreate(TableBase):
    restaurant_id: int

class TableUpdate(BaseModel):
    table_number: Optional[str] = None
    capacity: Optional[int] = None
    is_active: Optional[bool] = None

class Table(TableBase):
    id: int
    restaurant_id: int
    qr_code: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Category schemas
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: int = 0

class CategoryCreate(CategoryBase):
    restaurant_id: int

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None

class Category(CategoryBase):
    id: int
    restaurant_id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

# MenuItem schemas
class MenuItemBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    image_url: Optional[str] = None
    ingredients: Optional[List[str]] = []
    allergens: Optional[List[str]] = []
    customization_options: Optional[Dict[str, Any]] = {}
    is_vegetarian: bool = False
    is_vegan: bool = False
    is_gluten_free: bool = False
    preparation_time: int = 15
    sort_order: int = 0

class MenuItemCreate(MenuItemBase):
    restaurant_id: int
    category_id: int

class MenuItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    image_url: Optional[str] = None
    ingredients: Optional[List[str]] = None
    allergens: Optional[List[str]] = None
    customization_options: Optional[Dict[str, Any]] = None
    is_available: Optional[bool] = None
    is_vegetarian: Optional[bool] = None
    is_vegan: Optional[bool] = None
    is_gluten_free: Optional[bool] = None
    preparation_time: Optional[int] = None
    sort_order: Optional[int] = None
    category_id: Optional[int] = None

class MenuItem(MenuItemBase):
    id: int
    restaurant_id: int
    category_id: int
    is_available: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Order schemas
class OrderItemBase(BaseModel):
    menu_item_id: int
    quantity: int
    customizations: Optional[Dict[str, Any]] = {}
    special_instructions: Optional[str] = None

class OrderItemCreate(OrderItemBase):
    pass

class OrderItem(OrderItemBase):
    id: int
    order_id: int
    unit_price: float
    total_price: float
    created_at: datetime
    menu_item: MenuItem

    class Config:
        from_attributes = True

class OrderBase(BaseModel):
    special_instructions: Optional[str] = None

class OrderCreate(OrderBase):
    table_id: int
    items: List[OrderItemCreate]

class OrderUpdate(BaseModel):
    status: Optional[OrderStatus] = None
    special_instructions: Optional[str] = None

class Order(OrderBase):
    id: int
    restaurant_id: int
    table_id: int
    customer_id: int
    order_number: str
    status: OrderStatus
    subtotal: float
    tax_amount: float
    service_charge: float
    total_amount: float
    estimated_preparation_time: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    order_items: List[OrderItem] = []
    table: Table
    customer: User

    class Config:
        from_attributes = True

# Payment schemas
class PaymentBase(BaseModel):
    payment_method: PaymentMethod
    amount: float

class PaymentCreate(PaymentBase):
    order_id: int

class PaymentUpdate(BaseModel):
    status: Optional[PaymentStatus] = None
    transaction_id: Optional[str] = None
    external_transaction_id: Optional[str] = None
    payment_details: Optional[Dict[str, Any]] = None

class Payment(PaymentBase):
    id: int
    order_id: int
    status: PaymentStatus
    transaction_id: Optional[str] = None
    external_transaction_id: Optional[str] = None
    payment_details: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Service Request schemas
class ServiceRequestBase(BaseModel):
    request_type: str
    message: Optional[str] = None
    priority: int = 1

class ServiceRequestCreate(ServiceRequestBase):
    table_id: int

class ServiceRequestUpdate(BaseModel):
    status: Optional[ServiceRequestStatus] = None
    priority: Optional[int] = None

class ServiceRequest(ServiceRequestBase):
    id: int
    table_id: int
    customer_id: int
    status: ServiceRequestStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    table: Table
    customer: User

    class Config:
        from_attributes = True

# Authentication schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# Menu response schemas
class MenuResponse(BaseModel):
    categories: List[Category]
    items: List[MenuItem]

# Analytics schemas
class OrderAnalytics(BaseModel):
    total_orders: int
    total_revenue: float
    average_order_value: float
    popular_items: List[Dict[str, Any]]
    orders_by_status: Dict[str, int]
    revenue_by_day: List[Dict[str, Any]]

# WebSocket message schemas
class WebSocketMessage(BaseModel):
    type: str
    data: Dict[str, Any]
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# QR Code response
class QRCodeResponse(BaseModel):
    restaurant_id: int
    table_id: int
    table_number: str
    restaurant_name: str

