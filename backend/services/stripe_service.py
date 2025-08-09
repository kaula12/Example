import stripe
from typing import Dict, Any, Optional
from config import settings

class StripeService:
    def __init__(self):
        stripe.api_key = settings.stripe_secret_key
        self.publishable_key = settings.stripe_publishable_key
    
    async def create_payment_intent(
        self,
        amount: int,  # Amount in cents
        currency: str = "kes",
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Create a Stripe Payment Intent"""
        try:
            payment_intent = stripe.PaymentIntent.create(
                amount=amount,
                currency=currency,
                metadata=metadata or {},
                automatic_payment_methods={
                    'enabled': True,
                },
            )
            
            return {
                "success": True,
                "payment_intent_id": payment_intent.id,
                "client_secret": payment_intent.client_secret,
                "status": payment_intent.status,
                "amount": payment_intent.amount,
                "currency": payment_intent.currency
            }
        
        except stripe.error.CardError as e:
            return {
                "success": False,
                "error": "Card error",
                "error_code": e.code,
                "error_message": str(e)
            }
        
        except stripe.error.RateLimitError as e:
            return {
                "success": False,
                "error": "Rate limit error",
                "error_message": "Too many requests made to the API too quickly"
            }
        
        except stripe.error.InvalidRequestError as e:
            return {
                "success": False,
                "error": "Invalid request",
                "error_message": str(e)
            }
        
        except stripe.error.AuthenticationError as e:
            return {
                "success": False,
                "error": "Authentication error",
                "error_message": "Authentication with Stripe's API failed"
            }
        
        except stripe.error.APIConnectionError as e:
            return {
                "success": False,
                "error": "Network error",
                "error_message": "Network communication with Stripe failed"
            }
        
        except stripe.error.StripeError as e:
            return {
                "success": False,
                "error": "Stripe error",
                "error_message": str(e)
            }
        
        except Exception as e:
            return {
                "success": False,
                "error": "Unknown error",
                "error_message": str(e)
            }
    
    async def retrieve_payment_intent(self, payment_intent_id: str) -> Dict[str, Any]:
        """Retrieve a Payment Intent"""
        try:
            payment_intent = stripe.PaymentIntent.retrieve(payment_intent_id)
            
            return {
                "success": True,
                "payment_intent": {
                    "id": payment_intent.id,
                    "status": payment_intent.status,
                    "amount": payment_intent.amount,
                    "currency": payment_intent.currency,
                    "metadata": payment_intent.metadata,
                    "created": payment_intent.created
                }
            }
        
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def confirm_payment_intent(
        self, 
        payment_intent_id: str, 
        payment_method: str
    ) -> Dict[str, Any]:
        """Confirm a Payment Intent"""
        try:
            payment_intent = stripe.PaymentIntent.confirm(
                payment_intent_id,
                payment_method=payment_method
            )
            
            return {
                "success": True,
                "payment_intent": {
                    "id": payment_intent.id,
                    "status": payment_intent.status,
                    "amount": payment_intent.amount,
                    "currency": payment_intent.currency
                }
            }
        
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def create_refund(
        self, 
        payment_intent_id: str, 
        amount: Optional[int] = None,
        reason: str = "requested_by_customer"
    ) -> Dict[str, Any]:
        """Create a refund for a payment"""
        try:
            refund_data = {
                "payment_intent": payment_intent_id,
                "reason": reason
            }
            
            if amount:
                refund_data["amount"] = amount
            
            refund = stripe.Refund.create(**refund_data)
            
            return {
                "success": True,
                "refund": {
                    "id": refund.id,
                    "amount": refund.amount,
                    "currency": refund.currency,
                    "status": refund.status,
                    "reason": refund.reason
                }
            }
        
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def list_payment_methods(self, customer_id: str) -> Dict[str, Any]:
        """List payment methods for a customer"""
        try:
            payment_methods = stripe.PaymentMethod.list(
                customer=customer_id,
                type="card"
            )
            
            return {
                "success": True,
                "payment_methods": [
                    {
                        "id": pm.id,
                        "type": pm.type,
                        "card": {
                            "brand": pm.card.brand,
                            "last4": pm.card.last4,
                            "exp_month": pm.card.exp_month,
                            "exp_year": pm.card.exp_year
                        } if pm.card else None
                    }
                    for pm in payment_methods.data
                ]
            }
        
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def create_customer(
        self, 
        email: str, 
        name: str, 
        phone: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create a Stripe customer"""
        try:
            customer_data = {
                "email": email,
                "name": name
            }
            
            if phone:
                customer_data["phone"] = phone
            
            customer = stripe.Customer.create(**customer_data)
            
            return {
                "success": True,
                "customer": {
                    "id": customer.id,
                    "email": customer.email,
                    "name": customer.name,
                    "phone": customer.phone
                }
            }
        
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

