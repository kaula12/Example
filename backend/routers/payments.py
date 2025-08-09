from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from datetime import datetime
import stripe
import requests
import base64
import json

from database import get_db
from models.order import Order
from models.payment import Payment
from models.user import User
from routers.auth import get_current_active_user
from config import STRIPE_SECRET_KEY, MPESA_CONSUMER_KEY, MPESA_CONSUMER_SECRET, MPESA_SHORTCODE, MPESA_PASSKEY

router = APIRouter()

# Configure Stripe
if STRIPE_SECRET_KEY:
    stripe.api_key = STRIPE_SECRET_KEY

# Pydantic models
class PaymentCreate(BaseModel):
    order_id: int
    payment_method: str  # mpesa, stripe, cash
    phone_number: Optional[str] = None  # For M-Pesa
    amount: Optional[float] = None  # If different from order total

class PaymentResponse(BaseModel):
    id: int
    order_id: int
    payment_method: str
    amount: float
    currency: str
    status: str
    transaction_id: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class MPesaCallbackData(BaseModel):
    Body: dict

# M-Pesa utility functions
def get_mpesa_access_token():
    """Get M-Pesa access token"""
    if not MPESA_CONSUMER_KEY or not MPESA_CONSUMER_SECRET:
        raise HTTPException(status_code=500, detail="M-Pesa credentials not configured")
    
    api_url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
    
    # Create credentials
    credentials = base64.b64encode(f"{MPESA_CONSUMER_KEY}:{MPESA_CONSUMER_SECRET}".encode()).decode()
    
    headers = {
        "Authorization": f"Basic {credentials}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        return response.json()["access_token"]
    except requests.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Failed to get M-Pesa access token: {str(e)}")

def initiate_mpesa_payment(phone_number: str, amount: float, order_id: int):
    """Initiate M-Pesa STK Push payment"""
    access_token = get_mpesa_access_token()
    
    api_url = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
    
    # Generate timestamp
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    
    # Generate password
    password_string = f"{MPESA_SHORTCODE}{MPESA_PASSKEY}{timestamp}"
    password = base64.b64encode(password_string.encode()).decode()
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "BusinessShortCode": MPESA_SHORTCODE,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": int(amount),
        "PartyA": phone_number,
        "PartyB": MPESA_SHORTCODE,
        "PhoneNumber": phone_number,
        "CallBackURL": f"https://yourdomain.com/api/payments/mpesa/callback",
        "AccountReference": f"Order-{order_id}",
        "TransactionDesc": f"Payment for Order {order_id}"
    }
    
    try:
        response = requests.post(api_url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Failed to initiate M-Pesa payment: {str(e)}")

# Routes
@router.post("/", response_model=PaymentResponse)
async def create_payment(
    payment_data: PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a payment for an order"""
    # Get order
    order = db.query(Order).filter(Order.id == payment_data.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Check if user can pay for this order
    if current_user.role not in ["admin", "waiter"] and order.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to pay for this order")
    
    # Check if order is already paid
    if order.payment_status == "paid":
        raise HTTPException(status_code=400, detail="Order is already paid")
    
    # Use order total if amount not specified
    amount = payment_data.amount or order.total_amount
    
    # Create payment record
    payment = Payment(
        order_id=order.id,
        payment_method=payment_data.payment_method,
        amount=amount,
        currency="KES",
        status="pending"
    )
    
    db.add(payment)
    db.commit()
    db.refresh(payment)
    
    try:
        if payment_data.payment_method == "mpesa":
            if not payment_data.phone_number:
                raise HTTPException(status_code=400, detail="Phone number required for M-Pesa payment")
            
            # Initiate M-Pesa payment
            mpesa_response = initiate_mpesa_payment(payment_data.phone_number, amount, order.id)
            
            # Update payment with M-Pesa details
            payment.mpesa_checkout_request_id = mpesa_response.get("CheckoutRequestID")
            payment.mpesa_merchant_request_id = mpesa_response.get("MerchantRequestID")
            payment.mpesa_phone_number = payment_data.phone_number
            payment.gateway_response = mpesa_response
            payment.status = "processing"
            
        elif payment_data.payment_method == "stripe":
            if not STRIPE_SECRET_KEY:
                raise HTTPException(status_code=500, detail="Stripe not configured")
            
            # Create Stripe payment intent
            intent = stripe.PaymentIntent.create(
                amount=int(amount * 100),  # Stripe uses cents
                currency="kes",
                metadata={
                    "order_id": order.id,
                    "payment_id": payment.id
                }
            )
            
            # Update payment with Stripe details
            payment.stripe_payment_intent_id = intent.id
            payment.transaction_id = intent.id
            payment.gateway_response = intent
            payment.status = "processing"
            
        elif payment_data.payment_method == "cash":
            # Cash payment - mark as completed (to be confirmed by staff)
            payment.status = "completed"
            payment.processed_at = datetime.utcnow()
            
            # Update order payment status
            order.payment_method = "cash"
            order.payment_status = "paid"
            
        else:
            raise HTTPException(status_code=400, detail="Invalid payment method")
        
        db.commit()
        db.refresh(payment)
        
        return payment
        
    except Exception as e:
        # Update payment status to failed
        payment.status = "failed"
        payment.failure_reason = str(e)
        db.commit()
        raise HTTPException(status_code=500, detail=f"Payment processing failed: {str(e)}")

@router.get("/{payment_id}", response_model=PaymentResponse)
async def get_payment(
    payment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get payment details"""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    # Check permissions
    order = payment.order
    if current_user.role not in ["admin", "waiter"] and order.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this payment")
    
    return payment

@router.post("/mpesa/callback")
async def mpesa_callback(request: Request, db: Session = Depends(get_db)):
    """Handle M-Pesa payment callback"""
    try:
        callback_data = await request.json()
        
        # Extract callback data
        stk_callback = callback_data.get("Body", {}).get("stkCallback", {})
        checkout_request_id = stk_callback.get("CheckoutRequestID")
        result_code = stk_callback.get("ResultCode")
        result_desc = stk_callback.get("ResultDesc")
        
        if not checkout_request_id:
            return {"ResultCode": 1, "ResultDesc": "Invalid callback data"}
        
        # Find payment by checkout request ID
        payment = db.query(Payment).filter(
            Payment.mpesa_checkout_request_id == checkout_request_id
        ).first()
        
        if not payment:
            return {"ResultCode": 1, "ResultDesc": "Payment not found"}
        
        # Update payment status based on result
        if result_code == 0:  # Success
            # Extract transaction details
            callback_metadata = stk_callback.get("CallbackMetadata", {}).get("Item", [])
            
            for item in callback_metadata:
                if item.get("Name") == "MpesaReceiptNumber":
                    payment.mpesa_receipt_number = item.get("Value")
                elif item.get("Name") == "TransactionDate":
                    payment.processed_at = datetime.utcnow()
            
            payment.status = "completed"
            payment.transaction_id = payment.mpesa_receipt_number
            
            # Update order payment status
            order = payment.order
            order.payment_method = "mpesa"
            order.payment_status = "paid"
            
        else:  # Failed
            payment.status = "failed"
            payment.failure_reason = result_desc
            payment.failure_code = str(result_code)
        
        # Store full callback response
        payment.gateway_response = callback_data
        
        db.commit()
        
        return {"ResultCode": 0, "ResultDesc": "Success"}
        
    except Exception as e:
        print(f"M-Pesa callback error: {e}")
        return {"ResultCode": 1, "ResultDesc": "Internal server error"}

@router.post("/stripe/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle Stripe webhook events"""
    try:
        payload = await request.body()
        sig_header = request.headers.get("stripe-signature")
        
        # Verify webhook signature (in production)
        # event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
        
        # For now, just parse the JSON
        event = json.loads(payload)
        
        if event["type"] == "payment_intent.succeeded":
            payment_intent = event["data"]["object"]
            payment_intent_id = payment_intent["id"]
            
            # Find payment by Stripe payment intent ID
            payment = db.query(Payment).filter(
                Payment.stripe_payment_intent_id == payment_intent_id
            ).first()
            
            if payment:
                payment.status = "completed"
                payment.processed_at = datetime.utcnow()
                payment.transaction_id = payment_intent_id
                payment.gateway_response = payment_intent
                
                # Update order payment status
                order = payment.order
                order.payment_method = "stripe"
                order.payment_status = "paid"
                
                db.commit()
        
        elif event["type"] == "payment_intent.payment_failed":
            payment_intent = event["data"]["object"]
            payment_intent_id = payment_intent["id"]
            
            # Find payment by Stripe payment intent ID
            payment = db.query(Payment).filter(
                Payment.stripe_payment_intent_id == payment_intent_id
            ).first()
            
            if payment:
                payment.status = "failed"
                payment.failure_reason = payment_intent.get("last_payment_error", {}).get("message", "Payment failed")
                payment.gateway_response = payment_intent
                
                db.commit()
        
        return {"status": "success"}
        
    except Exception as e:
        print(f"Stripe webhook error: {e}")
        raise HTTPException(status_code=400, detail="Webhook processing failed")

@router.get("/order/{order_id}")
async def get_order_payments(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get all payments for an order"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Check permissions
    if current_user.role not in ["admin", "waiter"] and order.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view payments for this order")
    
    payments = db.query(Payment).filter(Payment.order_id == order_id).all()
    return payments

