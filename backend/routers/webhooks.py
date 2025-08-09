from fastapi import APIRouter, Request, HTTPException, Depends
from sqlalchemy.orm import Session
import stripe
import json
import models
from database import get_db
from config import settings

router = APIRouter()

# Set Stripe API key
stripe.api_key = settings.stripe_secret_key

@router.post("/stripe")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle Stripe webhooks"""
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')
    
    try:
        # Verify webhook signature (you should set this in production)
        # event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
        
        # For development, just parse the JSON
        event = json.loads(payload)
        
        if event['type'] == 'payment_intent.succeeded':
            payment_intent = event['data']['object']
            
            # Find payment by external transaction ID
            payment = db.query(models.Payment).filter(
                models.Payment.external_transaction_id == payment_intent['id']
            ).first()
            
            if payment:
                payment.status = models.PaymentStatus.COMPLETED
                payment.payment_details = payment_intent
                
                # Update order status
                payment.order.status = models.OrderStatus.CONFIRMED
                
                db.commit()
        
        elif event['type'] == 'payment_intent.payment_failed':
            payment_intent = event['data']['object']
            
            payment = db.query(models.Payment).filter(
                models.Payment.external_transaction_id == payment_intent['id']
            ).first()
            
            if payment:
                payment.status = models.PaymentStatus.FAILED
                payment.payment_details = payment_intent
                db.commit()
        
        return {"status": "success"}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/mpesa")
async def mpesa_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle M-Pesa webhooks"""
    try:
        payload = await request.json()
        
        # Extract M-Pesa callback data
        stk_callback = payload.get("Body", {}).get("stkCallback", {})
        checkout_request_id = stk_callback.get("CheckoutRequestID")
        result_code = stk_callback.get("ResultCode")
        
        if not checkout_request_id:
            return {"status": "error", "message": "Invalid callback data"}
        
        # Find payment by external transaction ID
        payment = db.query(models.Payment).filter(
            models.Payment.external_transaction_id == checkout_request_id
        ).first()
        
        if not payment:
            return {"status": "error", "message": "Payment not found"}
        
        # Update payment status based on result code
        if result_code == 0:  # Success
            payment.status = models.PaymentStatus.COMPLETED
            # Update order status
            payment.order.status = models.OrderStatus.CONFIRMED
            
            # Extract transaction details
            callback_metadata = stk_callback.get("CallbackMetadata", {}).get("Item", [])
            transaction_details = {}
            
            for item in callback_metadata:
                name = item.get("Name")
                value = item.get("Value")
                if name and value:
                    transaction_details[name] = value
            
            payment.payment_details = {
                "stk_callback": stk_callback,
                "transaction_details": transaction_details
            }
            
        else:  # Failed
            payment.status = models.PaymentStatus.FAILED
            payment.payment_details = {"stk_callback": stk_callback}
        
        db.commit()
        
        return {"status": "success"}
        
    except Exception as e:
        return {"status": "error", "message": str(e)}

@router.post("/mpesa/timeout")
async def mpesa_timeout(request: Request, db: Session = Depends(get_db)):
    """Handle M-Pesa timeout callbacks"""
    try:
        payload = await request.json()
        
        checkout_request_id = payload.get("CheckoutRequestID")
        if not checkout_request_id:
            return {"status": "error", "message": "Invalid timeout data"}
        
        # Find payment and mark as failed
        payment = db.query(models.Payment).filter(
            models.Payment.external_transaction_id == checkout_request_id
        ).first()
        
        if payment and payment.status == models.PaymentStatus.PENDING:
            payment.status = models.PaymentStatus.FAILED
            payment.payment_details = {
                "timeout": True,
                "timeout_data": payload
            }
            db.commit()
        
        return {"status": "success"}
        
    except Exception as e:
        return {"status": "error", "message": str(e)}

