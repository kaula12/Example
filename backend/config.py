from decouple import config
import os

# Database Configuration
DATABASE_URL = config(
    "DATABASE_URL", 
    default="postgresql://postgres:postgres123@localhost:5432/restaurant_ordering"
)

# Security Configuration
SECRET_KEY = config("SECRET_KEY", default="your-super-secret-key-change-in-production")
ALGORITHM = config("ALGORITHM", default="HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = config("ACCESS_TOKEN_EXPIRE_MINUTES", default=30, cast=int)

# Supabase Configuration
SUPABASE_URL = config("SUPABASE_URL", default="")
SUPABASE_SERVICE_KEY = config("SUPABASE_SERVICE_KEY", default="")

# Stripe Configuration
STRIPE_SECRET_KEY = config("STRIPE_SECRET_KEY", default="")
STRIPE_WEBHOOK_SECRET = config("STRIPE_WEBHOOK_SECRET", default="")

# M-Pesa Configuration
MPESA_CONSUMER_KEY = config("MPESA_CONSUMER_KEY", default="")
MPESA_CONSUMER_SECRET = config("MPESA_CONSUMER_SECRET", default="")
MPESA_SHORTCODE = config("MPESA_SHORTCODE", default="174379")
MPESA_PASSKEY = config("MPESA_PASSKEY", default="")
MPESA_CALLBACK_URL = config("MPESA_CALLBACK_URL", default="")

# Redis Configuration
REDIS_URL = config("REDIS_URL", default="redis://localhost:6379")

# Environment
ENVIRONMENT = config("ENVIRONMENT", default="development")

# CORS Configuration
ALLOWED_ORIGINS = config(
    "ALLOWED_ORIGINS", 
    default="http://localhost:3000,http://localhost:8080,http://localhost:8081",
    cast=lambda v: [s.strip() for s in v.split(',')]
)

# File Upload Configuration
MAX_FILE_SIZE = config("MAX_FILE_SIZE", default=5 * 1024 * 1024, cast=int)  # 5MB
UPLOAD_DIR = config("UPLOAD_DIR", default="uploads")

# Email Configuration (optional)
SMTP_HOST = config("SMTP_HOST", default="")
SMTP_PORT = config("SMTP_PORT", default=587, cast=int)
SMTP_USER = config("SMTP_USER", default="")
SMTP_PASSWORD = config("SMTP_PASSWORD", default="")

# Application Settings
APP_NAME = "Restaurant Table Ordering System"
APP_VERSION = "1.0.0"
DEBUG = config("DEBUG", default=True, cast=bool)

# Pagination
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

# Cache Settings
CACHE_TTL = config("CACHE_TTL", default=300, cast=int)  # 5 minutes

# Rate Limiting
RATE_LIMIT_PER_MINUTE = config("RATE_LIMIT_PER_MINUTE", default=60, cast=int)

