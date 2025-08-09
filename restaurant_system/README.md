# Restaurant Table Ordering System

A complete full-stack restaurant ordering system with QR code table scanning, real-time notifications, and integrated payment processing.

## 🚀 Features

### Customer Features
- **Table Selection**: Simple UI to choose table number
- **Menu Browsing**: Browse menu items by categories with images and descriptions
- **Order Customization**: Add items to cart with special instructions
- **Real-time Order Tracking**: Live updates on order status
- **Multiple Payment Options**: Stripe, M-Pesa, and cash payment support
- **Waiter Requests**: Call waiter directly from the table

### Staff Features
- **Waiter Dashboard**: Manage assigned tables and orders
- **Real-time Alerts**: Instant notifications for customer requests
- **Order Status Updates**: Update order status (preparing, ready, served)
- **Kitchen Dashboard**: Real-time incoming orders with preparation tracking

### Admin Features
- **Restaurant Management**: Complete restaurant operations control
- **Menu Management**: Full CRUD operations for menu items and categories
- **Table Management**: Create and manage tables with waiter assignments
- **Analytics Dashboard**: Sales reports and popular items tracking
- **User Management**: Manage staff roles and permissions

## 🛠️ Tech Stack

### Backend
- **FastAPI**: Modern Python web framework with automatic API documentation
- **Supabase**: PostgreSQL database with real-time capabilities
- **Firebase**: Authentication and Cloud Messaging for push notifications
- **Pydantic**: Data validation and serialization

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Riverpod**: Reactive state management
- **Go Router**: Declarative navigation
- **Firebase Messaging**: Push notifications
- **Supabase Client**: Database integration

## 📋 Prerequisites

- Python 3.8+
- Flutter SDK 3.10+
- Supabase account
- Firebase project
- Node.js (for Firebase CLI)

## 🚀 Setup Instructions

### 1. Backend Setup

```bash
cd restaurant_system/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your Supabase and Firebase credentials

# Set up Firebase service account
# Download your Firebase service account key and save as firebase-service-account.json
```

### 2. Database Setup (Supabase)

1. Create a new Supabase project
2. Run the SQL schema from `database/supabase_schema.sql` in your Supabase SQL editor
3. Update your `.env` file with Supabase URL and anon key

### 3. Firebase Setup

1. Create a new Firebase project
2. Enable Authentication and Cloud Messaging
3. Download the service account key
4. Add your Firebase configuration to the Flutter app

### 4. Frontend Setup

```bash
cd restaurant_system/frontend

# Install dependencies
flutter pub get

# Update configuration
# Edit lib/core/config/app_config.dart with your API endpoints and keys

# Run the app
flutter run
```

### 5. Start the Backend Server

```bash
cd restaurant_system/backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 📱 App Structure

### Backend Structure
```
backend/
├── main.py                 # FastAPI application entry point
├── requirements.txt        # Python dependencies
├── .env.example           # Environment variables template
└── firebase-service-account.json.example
```

### Frontend Structure
```
frontend/
├── lib/
│   ├── main.dart          # App entry point
│   ├── core/              # Core configuration and services
│   │   ├── config/        # App configuration
│   │   ├── models/        # Data models
│   │   ├── services/      # API and notification services
│   │   ├── theme/         # App theming
│   │   └── router/        # Navigation routing
│   └── features/          # Feature-based modules
│       ├── home/          # Home screen
│       ├── customer/      # Customer features
│       ├── waiter/        # Waiter features
│       ├── kitchen/       # Kitchen features
│       └── admin/         # Admin features
└── pubspec.yaml           # Flutter dependencies
```

## 🔧 Configuration

### Environment Variables (.env)
```
SUPABASE_URL=your-supabase-project-url
SUPABASE_KEY=your-supabase-anon-key
FIREBASE_PROJECT_ID=your-firebase-project-id
```

### App Configuration (app_config.dart)
```dart
static const String baseUrl = 'http://localhost:8000';
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

## 🔄 API Endpoints

### Menu Management
- `GET /api/menu` - Get all menu items
- `GET /api/menu/categories` - Get menu categories
- `POST /api/menu` - Create menu item (Admin)
- `PUT /api/menu/{id}` - Update menu item (Admin)
- `DELETE /api/menu/{id}` - Delete menu item (Admin)

### Order Management
- `POST /api/orders` - Create new order
- `GET /api/orders` - Get orders (with filters)
- `GET /api/orders/{id}` - Get specific order
- `PUT /api/orders/{id}/status` - Update order status

### Table Management
- `GET /api/tables` - Get all tables
- `POST /api/tables` - Create table (Admin)
- `PUT /api/tables/{id}` - Update table
- `PUT /api/tables/{table_number}/assign-waiter` - Assign waiter

### Notifications
- `POST /api/waiter-alerts` - Send waiter alert
- `GET /api/waiter-alerts` - Get waiter alerts
- `POST /api/fcm-token` - Register FCM token

### Payments
- `POST /api/payments` - Process payment

### Analytics
- `GET /api/analytics/daily-sales` - Get daily sales report
- `GET /api/analytics/popular-items` - Get popular items

## 🔐 Security Features

- **Environment Variables**: All sensitive data stored in environment variables
- **Input Validation**: Pydantic models for request/response validation
- **CORS Configuration**: Proper cross-origin resource sharing setup
- **Firebase Authentication**: Secure user authentication (structure ready)
- **Role-based Access**: Different permissions for different user roles

## 📊 Database Schema

### Main Tables
- **menu_items**: Restaurant menu with categories and pricing
- **tables**: Restaurant tables with waiter assignments
- **orders**: Customer orders with status tracking
- **order_items**: Individual items within orders
- **payments**: Payment transactions
- **waiter_alerts**: Customer service requests
- **user_tokens**: FCM tokens for push notifications

## 🔔 Real-time Features

- **Order Updates**: Live order status changes via Firebase
- **Waiter Alerts**: Instant notifications for customer requests
- **Kitchen Notifications**: Real-time new order alerts
- **Payment Updates**: Live payment confirmation updates

## 🧪 Testing

### Backend Testing
```bash
cd backend
python -m pytest tests/
```

### Frontend Testing
```bash
cd frontend
flutter test
```

## 📱 Mobile App Features

### Customer Flow
1. Select table number
2. Browse menu by categories
3. Add items to cart with customizations
4. Place order and make payment
5. Track order status in real-time
6. Request waiter assistance

### Staff Flow
1. View assigned tables and orders
2. Receive real-time customer alerts
3. Update order status
4. Manage table assignments

### Admin Flow
1. Manage menu items and categories
2. Assign tables to waiters
3. View sales analytics
4. Monitor all restaurant operations

## 🚀 Deployment

### Backend Deployment
- Deploy FastAPI app to cloud platforms (Heroku, AWS, GCP)
- Set up environment variables in production
- Configure Supabase for production database

### Frontend Deployment
- Build Flutter app for iOS/Android
- Configure Firebase for production
- Update API endpoints for production

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Review the API documentation at `/docs` when running the backend

## 🔮 Future Enhancements

- [ ] QR code generation for tables
- [ ] Advanced analytics and reporting
- [ ] Multi-restaurant support
- [ ] Inventory management
- [ ] Customer loyalty program
- [ ] Advanced payment integrations
- [ ] Offline mode support
- [ ] Multi-language support

---

**Built with ❤️ for modern restaurant operations**

