import httpx
import base64
from datetime import datetime
from typing import Dict, Any
from config import settings

class MPesaService:
    def __init__(self):
        self.consumer_key = settings.mpesa_consumer_key
        self.consumer_secret = settings.mpesa_consumer_secret
        self.shortcode = settings.mpesa_shortcode
        self.passkey = settings.mpesa_passkey
        self.callback_url = settings.mpesa_callback_url
        
        # M-Pesa API URLs (Sandbox)
        self.base_url = "https://sandbox.safaricom.co.ke"
        self.auth_url = f"{self.base_url}/oauth/v1/generate?grant_type=client_credentials"
        self.stk_push_url = f"{self.base_url}/mpesa/stkpush/v1/processrequest"
        
        # For production, use:
        # self.base_url = "https://api.safaricom.co.ke"
    
    async def get_access_token(self) -> str:
        """Get M-Pesa access token"""
        try:
            # Create basic auth header
            credentials = f"{self.consumer_key}:{self.consumer_secret}"
            encoded_credentials = base64.b64encode(credentials.encode()).decode()
            
            headers = {
                "Authorization": f"Basic {encoded_credentials}",
                "Content-Type": "application/json"
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.get(self.auth_url, headers=headers)
                
                if response.status_code == 200:
                    data = response.json()
                    return data.get("access_token")
                else:
                    raise Exception(f"Failed to get access token: {response.text}")
        
        except Exception as e:
            raise Exception(f"M-Pesa authentication error: {str(e)}")
    
    def generate_password(self) -> tuple:
        """Generate M-Pesa password and timestamp"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        password_string = f"{self.shortcode}{self.passkey}{timestamp}"
        password = base64.b64encode(password_string.encode()).decode()
        return password, timestamp
    
    async def initiate_stk_push(
        self, 
        phone_number: str, 
        amount: int, 
        account_reference: str, 
        transaction_desc: str
    ) -> Dict[str, Any]:
        """Initiate STK Push payment"""
        try:
            # Get access token
            access_token = await self.get_access_token()
            
            # Generate password and timestamp
            password, timestamp = self.generate_password()
            
            # Format phone number (ensure it starts with 254)
            if phone_number.startswith("0"):
                phone_number = "254" + phone_number[1:]
            elif phone_number.startswith("+254"):
                phone_number = phone_number[1:]
            elif not phone_number.startswith("254"):
                phone_number = "254" + phone_number
            
            # Prepare request payload
            payload = {
                "BusinessShortCode": self.shortcode,
                "Password": password,
                "Timestamp": timestamp,
                "TransactionType": "CustomerPayBillOnline",
                "Amount": amount,
                "PartyA": phone_number,
                "PartyB": self.shortcode,
                "PhoneNumber": phone_number,
                "CallBackURL": self.callback_url,
                "AccountReference": account_reference,
                "TransactionDesc": transaction_desc
            }
            
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self.stk_push_url,
                    json=payload,
                    headers=headers
                )
                
                data = response.json()
                
                if response.status_code == 200 and data.get("ResponseCode") == "0":
                    return {
                        "success": True,
                        "checkout_request_id": data.get("CheckoutRequestID"),
                        "merchant_request_id": data.get("MerchantRequestID"),
                        "response_code": data.get("ResponseCode"),
                        "response_description": data.get("ResponseDescription"),
                        "customer_message": data.get("CustomerMessage")
                    }
                else:
                    return {
                        "success": False,
                        "error": data.get("ResponseDescription", "Unknown error"),
                        "response_code": data.get("ResponseCode"),
                        "error_code": data.get("errorCode"),
                        "error_message": data.get("errorMessage")
                    }
        
        except Exception as e:
            return {
                "success": False,
                "error": f"STK Push failed: {str(e)}"
            }
    
    async def query_transaction_status(self, checkout_request_id: str) -> Dict[str, Any]:
        """Query the status of an STK Push transaction"""
        try:
            access_token = await self.get_access_token()
            password, timestamp = self.generate_password()
            
            query_url = f"{self.base_url}/mpesa/stkpushquery/v1/query"
            
            payload = {
                "BusinessShortCode": self.shortcode,
                "Password": password,
                "Timestamp": timestamp,
                "CheckoutRequestID": checkout_request_id
            }
            
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(query_url, json=payload, headers=headers)
                data = response.json()
                
                return {
                    "success": response.status_code == 200,
                    "data": data
                }
        
        except Exception as e:
            return {
                "success": False,
                "error": f"Query failed: {str(e)}"
            }

