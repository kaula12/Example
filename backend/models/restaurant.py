from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Restaurant(Base):
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    address = Column(Text, nullable=False)
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    website = Column(String(500), nullable=True)
    
    # Business hours
    opening_hours = Column(Text, nullable=True)  # JSON string
    
    # Location
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Settings
    is_active = Column(Boolean, default=True)
    accepts_online_orders = Column(Boolean, default=True)
    delivery_available = Column(Boolean, default=False)
    pickup_available = Column(Boolean, default=True)
    
    # Branding
    logo_url = Column(String(500), nullable=True)
    cover_image_url = Column(String(500), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    tables = relationship("Table", back_populates="restaurant", cascade="all, delete-orphan")
    categories = relationship("Category", back_populates="restaurant", cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="restaurant")
    
    def __repr__(self):
        return f"<Restaurant(id={self.id}, name='{self.name}')>"

class Table(Base):
    __tablename__ = "tables"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    table_number = Column(String(10), nullable=False)
    qr_code = Column(String(255), unique=True, nullable=False, index=True)
    capacity = Column(Integer, default=4)
    location = Column(String(100), nullable=True)  # e.g., "Window side", "Patio"
    
    # Status
    is_active = Column(Boolean, default=True)
    is_occupied = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    restaurant = relationship("Restaurant", back_populates="tables")
    orders = relationship("Order", back_populates="table")
    service_requests = relationship("ServiceRequest", back_populates="table")
    
    def __repr__(self):
        return f"<Table(id={self.id}, number='{self.table_number}', qr='{self.qr_code}')>"

