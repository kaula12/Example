# 🍽️ Restaurant Table Ordering System

A complete full-stack restaurant ordering system with QR code table scanning, real-time order updates, and integrated payment processing.

## 🚀 Features

### Customer Features
- **QR Code Scanning**: Scan table QR codes to access the menu
- **Digital Menu**: Browse menu by categories with images and descriptions
- **Customization**: Add customizations and special instructions to orders
- **Real-time Updates**: Live order status updates via WebSocket
- **Multiple Payment Options**: M-Pesa, Stripe (card), and cash payments
- **Service Requests**: Request water, bill, assistance, or cleanup from your table

### Staff Features
- **Kitchen Dashboard**: Real-time incoming orders with preparation tracking
- **Order Management**: Update order status (preparing, ready, served)
- **Service Requests**: Manage customer service requests
- **Real-time Notifications**: Instant notifications for new orders and requests

### Admin Features
- **Restaurant Management**: Manage restaurant details and settings
- **Menu Management**: Add, edit, and organize menu items and categories
- **Table Management**: Create and manage tables with QR codes
- **Sales Analytics**: View daily, weekly, and monthly sales reports
- **User Management**: Manage staff roles and permissions

## 🛠️ Tech Stack

### Backend
- **FastAPI**: Modern Python web framework
- **PostgreSQL**: Robust relational database
- **SQLAlchemy**: Python SQL toolkit and ORM
- **Alembic**: Database migration tool
- **WebSockets**: Real-time communication
- **JWT**: Secure authentication
- **Stripe & M-Pesa**: Payment processing

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Riverpod**: State management
- **Go Router**: Navigation
- **Dio**: HTTP client
- **WebSocket**: Real-time updates
- **QR Scanner**: QR code scanning

### Infrastructure
- **Docker**: Containerization
- **PostgreSQL**: Database container
- **Redis**: Caching (optional)
- **Nginx**: Reverse proxy (production)

## 🐳 Quick Start with Docker

### Prerequisites
- Docker and Docker Compose installed
- Flutter SDK (for mobile app development)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd restaurant-ordering-system
```

### 2. Start Backend Services
```bash
# Start PostgreSQL and Redis
docker-compose up -d

# Verify containers are running
docker ps
```

### 3. Setup Backend
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create environment file
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
alembic upgrade head

# Seed sample data
python seed_data.py

# Start backend server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Setup Frontend
```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run

# Or for web
flutter run -d chrome
```

## 🔧 Configuration

### Backend Environment Variables (.env)
```env
# Database
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/restaurant_ordering

# Security
SECRET_KEY=your-super-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Supabase (Optional)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-supabase-service-key

# Stripe (Optional)
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key

# M-Pesa (Optional)
MPESA_CONSUMER_KEY=your_mpesa_consumer_key
MPESA_CONSUMER_SECRET=your_mpesa_consumer_secret
MPESA_SHORTCODE=174379
MPESA_PASSKEY=your_mpesa_passkey

# Environment
ENVIRONMENT=development
```

### Frontend Configuration
Edit `frontend/lib/core/constants/app_constants.dart`:
```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
}
```

## 📱 Usage

### For Customers
1. **Scan QR Code**: Use the app to scan the QR code on your table
2. **Browse Menu**: Explore menu categories and items
3. **Add to Cart**: Select items with customizations
4. **Place Order**: Review and confirm your order
5. **Make Payment**: Pay via M-Pesa, card, or choose cash
6. **Track Order**: Monitor your order status in real-time
7. **Request Service**: Use service buttons for assistance

### For Staff
1. **Login**: Use staff credentials to access the dashboard
2. **View Orders**: See incoming orders in real-time
3. **Update Status**: Mark orders as preparing, ready, or served
4. **Handle Requests**: Respond to customer service requests
5. **Manage Menu**: Add or update menu items (admin only)

## 🗄️ Database Schema

### Core Tables
- **restaurants**: Restaurant information
- **tables**: Table details with QR codes
- **users**: User accounts and roles
- **categories**: Menu categories
- **menu_items**: Menu items with details
- **orders**: Customer orders
- **order_items**: Individual order items
- **payments**: Payment transactions
- **service_requests**: Customer service requests

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/token` - Login and get token
- `GET /api/auth/me` - Get current user

### Menu
- `GET /api/menu/restaurant/{id}` - Get restaurant menu
- `GET /api/menu/items/{id}` - Get menu item details
- `GET /api/menu/search` - Search menu items

### Orders
- `POST /api/orders` - Create new order
- `GET /api/orders/{id}` - Get order details
- `PUT /api/orders/{id}/status` - Update order status
- `POST /api/orders/service-requests` - Create service request

### Payments
- `POST /api/payments` - Process payment
- `GET /api/payments/{id}` - Get payment details
- `POST /api/payments/mpesa/callback` - M-Pesa callback

### Admin
- `GET /api/admin/analytics/sales` - Sales analytics
- `POST /api/admin/menu-items` - Create menu item
- `PUT /api/admin/menu-items/{id}` - Update menu item

## 🔄 Real-time Features

### WebSocket Events
- **order_update**: Order status changes
- **service_request**: New service requests
- **payment_update**: Payment status changes
- **table_status_update**: Table availability changes

### Connection
```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:8000/ws/1?user_role=customer');

// Listen for updates
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
```

### Sample Data
The system includes comprehensive sample data:
- 1 Restaurant (Savory Delights Restaurant)
- 8 Tables with QR codes
- 6 Menu categories
- 20+ Menu items
- Sample orders and service requests
- Test user accounts

### Test Accounts
```
Admin: admin@savorydelights.co.ke / admin123
Kitchen: kitchen@savorydelights.co.ke / kitchen123
Waiter: waiter@savorydelights.co.ke / waiter123
Customer: customer@example.com / customer123
```

## 🚀 Deployment

### Production Setup
1. **Environment**: Set `ENVIRONMENT=production` in .env
2. **Database**: Use managed PostgreSQL service
3. **Secrets**: Use secure secret keys and API keys
4. **SSL**: Enable HTTPS with SSL certificates
5. **Monitoring**: Set up logging and monitoring

### Docker Production
```bash
# Build and run with production profile
docker-compose --profile production up -d
```

## 📊 Monitoring

### Health Checks
- Backend: `GET /health`
- Database: Built-in health checks in docker-compose
- WebSocket: Connection statistics at `/api/ws/connections/stats`

### Logging
- Structured logging with timestamps
- Error tracking and reporting
- Performance monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Common Issues

**Database Connection Error**
```bash
# Check if PostgreSQL is running
docker ps

# Restart database
docker-compose restart postgres
```

**Port Already in Use**
```bash
# Check what's using port 5432
netstat -tulpn | grep 5432

# Kill the process or change port in docker-compose.yml
```

**Flutter Build Issues**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Getting Help
- Check the logs: `docker-compose logs`
- Review the API docs: `http://localhost:8000/docs`
- Test endpoints with the interactive API documentation

## 🎉 Features Roadmap

- [ ] Push notifications
- [ ] Loyalty program
- [ ] Multi-restaurant support
- [ ] Advanced analytics
- [ ] Inventory management
- [ ] Staff scheduling
- [ ] Customer reviews
- [ ] Delivery integration

---

**Built with ❤️ for the restaurant industry**

