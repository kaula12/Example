from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    
    # Payment details
    payment_method = Column(String(50), nullable=False)  # mpesa, stripe, cash
    payment_provider = Column(String(50), nullable=True)  # stripe, safaricom, etc.
    transaction_id = Column(String(255), unique=True, nullable=True, index=True)
    external_transaction_id = Column(String(255), nullable=True)  # Provider's transaction ID
    
    # Amount details
    amount = Column(Float, nullable=False)
    currency = Column(String(3), default="KES")
    
    # Status
    status = Column(String(50), default="pending")  # pending, processing, completed, failed, cancelled, refunded
    
    # Payment gateway response
    gateway_response = Column(JSON, nullable=True)  # Store full response from payment gateway
    
    # M-Pesa specific fields
    mpesa_checkout_request_id = Column(String(255), nullable=True)
    mpesa_merchant_request_id = Column(String(255), nullable=True)
    mpesa_receipt_number = Column(String(255), nullable=True)
    mpesa_phone_number = Column(String(20), nullable=True)
    
    # Stripe specific fields
    stripe_payment_intent_id = Column(String(255), nullable=True)
    stripe_charge_id = Column(String(255), nullable=True)
    
    # Failure details
    failure_reason = Column(Text, nullable=True)
    failure_code = Column(String(50), nullable=True)
    
    # Refund information
    refund_amount = Column(Float, nullable=True)
    refund_reason = Column(Text, nullable=True)
    refunded_at = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    processed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    order = relationship("Order", back_populates="payments")
    
    def __repr__(self):
        return f"<Payment(id={self.id}, method='{self.payment_method}', amount={self.amount}, status='{self.status}')>"

