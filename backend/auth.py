from datetime import datetime, timedelta
from typing import Optional, Union
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from supabase import create_client, Client
import models
from database import get_db
from config import settings

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT token scheme
security = HTTPBearer()

# Supabase client
supabase: Client = create_client(settings.supabase_url, settings.supabase_key) if settings.supabase_url else None

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt

def verify_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError:
        return None

def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_id(db: Session, user_id: int) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_supabase_id(db: Session, supabase_id: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.supabase_id == supabase_id).first()

def create_user(db: Session, user_data: dict) -> models.User:
    db_user = models.User(**user_data)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # First try to verify with our JWT
        payload = verify_token(credentials.credentials)
        if payload:
            user_id: int = payload.get("sub")
            if user_id is None:
                raise credentials_exception
            user = get_user_by_id(db, user_id=int(user_id))
            if user is None:
                raise credentials_exception
            return user
        
        # If JWT fails, try Supabase token verification
        if supabase:
            try:
                supabase_user = supabase.auth.get_user(credentials.credentials)
                if supabase_user and supabase_user.user:
                    user = get_user_by_supabase_id(db, supabase_user.user.id)
                    if user:
                        return user
                    # Create user if doesn't exist
                    user_data = {
                        "email": supabase_user.user.email,
                        "full_name": supabase_user.user.user_metadata.get("full_name", ""),
                        "supabase_id": supabase_user.user.id,
                        "role": models.UserRole.CUSTOMER
                    }
                    return create_user(db, user_data)
            except Exception:
                pass
        
        raise credentials_exception
    except Exception:
        raise credentials_exception

def require_role(allowed_roles: list[models.UserRole]):
    def role_checker(current_user: models.User = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions"
            )
        return current_user
    return role_checker

# Role-specific dependencies
def get_admin_user(current_user: models.User = Depends(require_role([models.UserRole.ADMIN]))):
    return current_user

def get_kitchen_user(current_user: models.User = Depends(require_role([models.UserRole.KITCHEN, models.UserRole.ADMIN]))):
    return current_user

def get_waiter_user(current_user: models.User = Depends(require_role([models.UserRole.WAITER, models.UserRole.ADMIN]))):
    return current_user

