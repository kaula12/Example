# Restaurant Table Ordering System - Project Structure

## Complete File Structure

```
restaurant-ordering-system/
├── README.md
├── PROJECT_STRUCTURE.md
├── docker-compose.yml
├── .gitignore
│
├── backend/                          # FastAPI Backend
│   ├── main.py                      # FastAPI application entry point
│   ├── config.py                    # Configuration settings
│   ├── database.py                  # Database connection and session
│   ├── dependencies.py              # FastAPI dependencies
│   ├── requirements.txt             # Python dependencies
│   ├── Dockerfile                   # Docker configuration
│   ├── .env.example                 # Environment variables template
│   │
│   ├── models/                      # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py                  # User model
│   │   ├── restaurant.py            # Restaurant model
│   │   ├── menu.py                  # Menu and category models
│   │   ├── order.py                 # Order models
│   │   └── payment.py               # Payment models
│   │
│   ├── schemas/                     # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── user.py                  # User schemas
│   │   ├── restaurant.py            # Restaurant schemas
│   │   ├── menu.py                  # Menu schemas
│   │   ├── order.py                 # Order schemas
│   │   └── payment.py               # Payment schemas
│   │
│   ├── routers/                     # API route handlers
│   │   ├── __init__.py
│   │   ├── auth.py                  # Authentication routes
│   │   ├── menu.py                  # Menu routes
│   │   ├── orders.py                # Order routes
│   │   ├── payments.py              # Payment routes
│   │   ├── admin.py                 # Admin routes
│   │   └── websocket.py             # WebSocket routes
│   │
│   ├── services/                    # Business logic services
│   │   ├── __init__.py
│   │   ├── auth_service.py          # Authentication service
│   │   ├── menu_service.py          # Menu service
│   │   ├── order_service.py         # Order service
│   │   ├── payment_service.py       # Payment service
│   │   ├── mpesa_service.py         # M-Pesa integration
│   │   ├── stripe_service.py        # Stripe integration
│   │   └── websocket_service.py     # WebSocket service
│   │
│   ├── utils/                       # Utility functions
│   │   ├── __init__.py
│   │   ├── security.py              # Security utilities
│   │   ├── email.py                 # Email utilities
│   │   └── helpers.py               # General helpers
│   │
│   ├── alembic/                     # Database migrations
│   │   ├── env.py                   # Alembic environment
│   │   ├── script.py.mako           # Migration template
│   │   └── versions/                # Migration files
│   │       └── 001_initial_migration.py
│   │
│   ├── tests/                       # Backend tests
│   │   ├── __init__.py
│   │   └── test_api.py              # API tests
│   │
│   └── seed_data.py                 # Database seeding script
│
├── frontend/                        # Flutter Frontend
│   ├── pubspec.yaml                 # Flutter dependencies
│   ├── analysis_options.yaml        # Dart analysis options
│   │
│   ├── lib/                         # Dart source code
│   │   ├── main.dart                # App entry point
│   │   │
│   │   ├── core/                    # Core app configuration
│   │   │   ├── constants.dart       # App constants
│   │   │   ├── theme.dart           # App theme
│   │   │   ├── providers.dart       # Riverpod providers
│   │   │   └── app_router.dart      # Navigation routing
│   │   │
│   │   ├── models/                  # Data models
│   │   │   └── models.dart          # All data models
│   │   │
│   │   ├── services/                # API and external services
│   │   │   ├── api_service.dart     # HTTP API service
│   │   │   ├── auth_service.dart    # Authentication service
│   │   │   └── websocket_service.dart # WebSocket service
│   │   │
│   │   ├── screens/                 # UI screens
│   │   │   ├── splash_screen.dart   # Splash screen
│   │   │   ├── qr_scanner_screen.dart # QR code scanner
│   │   │   ├── menu_screen.dart     # Menu display
│   │   │   ├── item_detail_screen.dart # Item details
│   │   │   ├── cart_screen.dart     # Shopping cart
│   │   │   ├── checkout_screen.dart # Checkout process
│   │   │   ├── order_tracking_screen.dart # Order tracking
│   │   │   ├── kitchen_dashboard.dart # Kitchen dashboard
│   │   │   ├── admin_dashboard.dart # Admin dashboard
│   │   │   ├── menu_management_screen.dart # Menu management
│   │   │   ├── analytics_screen.dart # Analytics
│   │   │   ├── profile_screen.dart  # User profile
│   │   │   └── auth/                # Authentication screens
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   │
│   │   └── widgets/                 # Reusable UI components
│   │       ├── menu_item_card.dart  # Menu item card
│   │       ├── category_chip.dart   # Category filter chip
│   │       └── cart_fab.dart        # Cart floating action button
│   │
│   ├── android/                     # Android configuration
│   │   └── app/src/main/
│   │       └── AndroidManifest.xml  # Android permissions
│   │
│   ├── ios/                         # iOS configuration
│   │   └── Runner/
│   │       └── Info.plist           # iOS permissions
│   │
│   └── assets/                      # Static assets
│       ├── images/                  # Image assets
│       ├── icons/                   # Icon assets
│       └── animations/              # Animation assets
```

## Key Components

### Backend Architecture

#### **FastAPI Application (main.py)**
- Main application setup with CORS, middleware, and route registration
- WebSocket endpoint for real-time communication
- Health check endpoint

#### **Database Layer**
- **Models**: SQLAlchemy ORM models for all entities
- **Schemas**: Pydantic models for request/response validation
- **Database**: PostgreSQL with connection pooling
- **Migrations**: Alembic for database schema management

#### **API Routes**
- **Authentication**: User registration, login, JWT handling
- **Menu**: QR scanning, menu retrieval, search
- **Orders**: Order creation, status updates, kitchen management
- **Payments**: M-Pesa, Stripe, and cash payment processing
- **Admin**: Restaurant management, analytics, reporting
- **WebSocket**: Real-time order and status updates

#### **Services Layer**
- **Auth Service**: JWT token management, Supabase integration
- **Menu Service**: Menu operations and caching
- **Order Service**: Order processing and workflow
- **Payment Service**: Payment gateway integrations
- **WebSocket Service**: Real-time communication management

### Frontend Architecture

#### **Flutter Application Structure**
- **Clean Architecture**: Separation of concerns with clear layers
- **State Management**: Riverpod for reactive state management
- **Navigation**: Go Router for declarative routing
- **HTTP Client**: Dio for API communication
- **WebSocket**: Real-time updates from backend

#### **Core Layer**
- **Constants**: App-wide configuration and constants
- **Theme**: Material Design theme configuration
- **Providers**: Riverpod providers for state management
- **Router**: Navigation configuration and route guards

#### **Data Layer**
- **Models**: Dart classes for data representation
- **Services**: API communication and external integrations
- **Providers**: State management and data caching

#### **Presentation Layer**
- **Screens**: Full-screen UI components
- **Widgets**: Reusable UI components
- **Responsive Design**: Adaptive layouts for different screen sizes

## Data Flow

### Customer Order Flow
1. **QR Scan**: Customer scans table QR code
2. **Menu Browse**: Load restaurant menu and categories
3. **Item Selection**: Add items to cart with customizations
4. **Checkout**: Review order and select payment method
5. **Payment**: Process payment via M-Pesa, card, or cash
6. **Order Tracking**: Real-time status updates via WebSocket

### Kitchen Workflow
1. **Order Receipt**: New orders appear in kitchen dashboard
2. **Order Processing**: Kitchen staff update order status
3. **Real-time Updates**: Status changes broadcast to customers
4. **Service Coordination**: Integration with waiter notifications

### Admin Operations
1. **Menu Management**: Add, edit, remove menu items and categories
2. **Analytics**: View sales data, popular items, peak hours
3. **Order Management**: Monitor all orders and their status
4. **Staff Management**: Manage user accounts and permissions

## Security Features

### Authentication & Authorization
- **JWT Tokens**: Secure API authentication
- **Supabase Integration**: Third-party authentication provider
- **Role-based Access**: Customer, waiter, kitchen, admin roles
- **Password Security**: Bcrypt hashing for passwords

### API Security
- **CORS Configuration**: Controlled cross-origin requests
- **Input Validation**: Pydantic schema validation
- **SQL Injection Prevention**: SQLAlchemy ORM protection
- **Rate Limiting**: API endpoint protection

### Data Protection
- **Environment Variables**: Sensitive data in environment files
- **Database Security**: Connection encryption and access control
- **Payment Security**: PCI compliance for card payments
- **WebSocket Security**: Authenticated connections only

## Deployment Architecture

### Development Environment
- **Docker Compose**: Local development with PostgreSQL and Redis
- **Hot Reload**: FastAPI and Flutter development servers
- **Database Seeding**: Sample data for testing

### Production Deployment
- **Containerization**: Docker containers for scalability
- **Database**: Managed PostgreSQL service
- **CDN**: Static asset delivery
- **Load Balancing**: Multiple API instances
- **SSL/TLS**: HTTPS encryption
- **Monitoring**: Application and infrastructure monitoring

## Testing Strategy

### Backend Testing
- **Unit Tests**: Individual function testing
- **Integration Tests**: API endpoint testing
- **Database Tests**: Model and migration testing
- **WebSocket Tests**: Real-time communication testing

### Frontend Testing
- **Widget Tests**: UI component testing
- **Integration Tests**: Screen flow testing
- **Unit Tests**: Business logic testing
- **End-to-End Tests**: Complete user journey testing

## Performance Considerations

### Backend Optimization
- **Database Indexing**: Optimized queries
- **Connection Pooling**: Efficient database connections
- **Caching**: Redis for frequently accessed data
- **Async Processing**: Non-blocking operations

### Frontend Optimization
- **State Management**: Efficient state updates
- **Image Caching**: Cached network images
- **Lazy Loading**: On-demand data loading
- **Bundle Optimization**: Minimized app size

This architecture provides a scalable, maintainable, and secure foundation for a complete restaurant ordering system with real-time capabilities and modern user experience.

