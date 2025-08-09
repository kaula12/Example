from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    table_id = Column(Integer, ForeignKey("tables.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # Nullable for guest orders
    
    # Order details
    order_number = Column(String(50), unique=True, nullable=False, index=True)
    status = Column(String(50), default="pending")  # pending, confirmed, preparing, ready, served, cancelled
    
    # Pricing
    subtotal = Column(Float, nullable=False)
    tax_amount = Column(Float, default=0.0)
    service_charge = Column(Float, default=0.0)
    discount_amount = Column(Float, default=0.0)
    total_amount = Column(Float, nullable=False)
    
    # Payment
    payment_method = Column(String(50), nullable=True)  # mpesa, card, cash
    payment_status = Column(String(50), default="pending")  # pending, paid, failed, refunded
    
    # Customer information (for guest orders)
    customer_name = Column(String(255), nullable=True)
    customer_phone = Column(String(20), nullable=True)
    customer_email = Column(String(255), nullable=True)
    
    # Special instructions
    special_instructions = Column(Text, nullable=True)
    
    # Timing
    estimated_preparation_time = Column(Integer, nullable=True)  # minutes
    preparation_started_at = Column(DateTime(timezone=True), nullable=True)
    ready_at = Column(DateTime(timezone=True), nullable=True)
    served_at = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    restaurant = relationship("Restaurant", back_populates="orders")
    table = relationship("Table", back_populates="orders")
    customer = relationship("User")
    order_items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="order")
    
    def __repr__(self):
        return f"<Order(id={self.id}, number='{self.order_number}', status='{self.status}')>"

class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    menu_item_id = Column(Integer, ForeignKey("menu_items.id"), nullable=False)
    
    # Item details
    quantity = Column(Integer, nullable=False, default=1)
    unit_price = Column(Float, nullable=False)
    total_price = Column(Float, nullable=False)
    
    # Customizations
    customizations = Column(JSON, nullable=True)  # JSON object with customization choices
    special_instructions = Column(Text, nullable=True)
    
    # Status
    status = Column(String(50), default="pending")  # pending, preparing, ready, served
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    order = relationship("Order", back_populates="order_items")
    menu_item = relationship("MenuItem", back_populates="order_items")
    
    def __repr__(self):
        return f"<OrderItem(id={self.id}, quantity={self.quantity}, price={self.total_price})>"

class ServiceRequest(Base):
    __tablename__ = "service_requests"

    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Request details
    request_type = Column(String(50), nullable=False)  # water, bill, assistance, cleanup
    message = Column(Text, nullable=True)
    priority = Column(Integer, default=1)  # 1=low, 2=medium, 3=high, 4=urgent
    
    # Status
    status = Column(String(50), default="pending")  # pending, acknowledged, in_progress, completed, cancelled
    
    # Assignment
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=True)  # Staff member assigned
    
    # Timing
    acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    table = relationship("Table", back_populates="service_requests")
    customer = relationship("User", foreign_keys=[customer_id])
    assigned_staff = relationship("User", foreign_keys=[assigned_to])
    
    def __repr__(self):
        return f"<ServiceRequest(id={self.id}, type='{self.request_type}', status='{self.status}')>"

