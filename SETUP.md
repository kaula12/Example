# 🚀 Complete Setup Guide - Restaurant Ordering System

This guide will walk you through setting up the complete restaurant ordering system using Docker for the easiest setup experience.

## 📋 Prerequisites

### Required Software
1. **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
2. **Flutter SDK** - [Install guide](https://docs.flutter.dev/get-started/install)
3. **Git** - [Download here](https://git-scm.com/downloads)

### Optional (for development)
- **Python 3.11+** - For backend development
- **Node.js** - For additional tooling
- **VS Code** - Recommended IDE

## 🐳 Step 1: Docker Setup

### Install Docker Desktop
1. Download Docker Desktop for your operating system
2. Install and start Docker Desktop
3. Verify installation:
```bash
docker --version
docker-compose --version
```

## 📁 Step 2: Project Setup

### Clone the Repository
```bash
git clone <your-repository-url>
cd restaurant-ordering-system
```

### Project Structure
```
restaurant-ordering-system/
├── docker-compose.yml          # Docker services configuration
├── backend/                    # FastAPI backend
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py
│   ├── .env.example
│   └── ...
├── frontend/                   # Flutter frontend
│   ├── pubspec.yaml
│   ├── lib/
│   └── ...
├── nginx.conf                  # Nginx configuration
└── README.md
```

## 🗄️ Step 3: Start Database Services

### Start PostgreSQL and Redis
```bash
# Start database services
docker-compose up -d postgres redis

# Verify services are running
docker ps
```

You should see:
```
CONTAINER ID   IMAGE           PORTS                    NAMES
abc123...      postgres:15     0.0.0.0:5432->5432/tcp   restaurant-postgres
def456...      redis:7-alpine  0.0.0.0:6379->6379/tcp   restaurant-redis
```

### Test Database Connection
```bash
# Connect to PostgreSQL
docker exec -it restaurant-postgres psql -U postgres -d restaurant_ordering

# You should see the PostgreSQL prompt
restaurant_ordering=#

# Exit with \q
\q
```

## ⚙️ Step 4: Backend Setup

### Navigate to Backend Directory
```bash
cd backend
```

### Create Python Virtual Environment
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Verify activation (you should see (venv) in your prompt)
```

### Install Dependencies
```bash
# Install Python packages
pip install -r requirements.txt
```

### Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your settings
# Minimum required configuration:
```

Edit `.env` file:
```env
# Database (using Docker PostgreSQL)
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/restaurant_ordering

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Optional: Add Supabase, Stripe, M-Pesa credentials if you have them
SUPABASE_URL=
SUPABASE_SERVICE_KEY=
STRIPE_SECRET_KEY=
MPESA_CONSUMER_KEY=
MPESA_CONSUMER_SECRET=

# Environment
ENVIRONMENT=development
```

### Initialize Database
```bash
# Run database migrations
alembic upgrade head

# Seed sample data
python seed_data.py
```

You should see:
```
🌱 Starting database seeding...
📍 Creating restaurant...
🪑 Creating tables...
👥 Creating users...
📂 Creating menu categories...
🍽️ Creating menu items...
📋 Creating sample order...
🔔 Creating sample service request...
✅ Database seeding completed successfully!
```

### Start Backend Server
```bash
# Start FastAPI server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
```

### Test Backend API
Open your browser and go to:
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## 📱 Step 5: Frontend Setup

### Open New Terminal
Keep the backend running and open a new terminal window.

### Navigate to Frontend Directory
```bash
cd frontend
```

### Install Flutter Dependencies
```bash
# Get Flutter packages
flutter pub get
```

### Configure Frontend
Edit `lib/core/constants/app_constants.dart`:
```dart
class AppConstants {
  // API Configuration - Update if needed
  static const String baseUrl = 'http://localhost:8000';
  static const String wsUrl = 'ws://localhost:8000/ws';

  // Add your credentials if you have them
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
}
```

### Run Flutter App
```bash
# Run on connected device/emulator
flutter run

# Or run on web browser
flutter run -d chrome

# Or run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## ✅ Step 6: Verify Everything Works

### 1. Check Docker Services
```bash
docker ps
```
Should show 2 containers running (postgres and redis).

### 2. Test Backend API
Visit http://localhost:8000/docs - should show FastAPI documentation.

### 3. Test Database Data
```bash
# Connect to database
docker exec -it restaurant-postgres psql -U postgres -d restaurant_ordering

# Check sample data
SELECT name FROM restaurants;
SELECT table_number, qr_code FROM tables LIMIT 5;
SELECT name FROM categories;

# Exit
\q
```

### 4. Test Flutter App
The Flutter app should open and show:
- QR Scanner screen (main screen)
- Navigation to browse menu
- Sample restaurant data

### 5. Test QR Code Functionality
Use one of these sample QR codes from the database:
- `QR_1_T01_<random>`
- `QR_1_T02_<random>`
- etc.

You can find the exact QR codes by running:
```sql
SELECT table_number, qr_code FROM tables;
```

## 🧪 Step 7: Test Complete Flow

### Test User Accounts
Use these pre-created accounts:

**Admin Account:**
- Email: `admin@savorydelights.co.ke`
- Password: `admin123`

**Customer Account:**
- Email: `customer@example.com`
- Password: `customer123`

**Staff Accounts:**
- Kitchen: `kitchen@savorydelights.co.ke` / `kitchen123`
- Waiter: `waiter@savorydelights.co.ke` / `waiter123`

### Test Order Flow
1. **Scan QR Code** (or manually enter a QR code)
2. **Browse Menu** - Should show categories and items
3. **Add Items to Cart** - Test customizations
4. **Place Order** - Should create order successfully
5. **View Order Status** - Should show pending order

### Test Real-time Updates
1. Open the Flutter app (customer view)
2. Open http://localhost:8000/docs (admin view)
3. Place an order in the app
4. Update order status via API docs
5. Should see real-time updates in the app

## 🔧 Troubleshooting

### Common Issues

#### Docker Issues
```bash
# If containers won't start
docker-compose down
docker-compose up -d

# If port conflicts
netstat -tulpn | grep 5432  # Check what's using port 5432
# Kill the process or change port in docker-compose.yml
```

#### Backend Issues
```bash
# If database connection fails
docker exec -it restaurant-postgres psql -U postgres -c "SELECT version();"

# If migrations fail
alembic downgrade base
alembic upgrade head

# If seeding fails
python seed_data.py  # Run again
```

#### Frontend Issues
```bash
# If Flutter build fails
flutter clean
flutter pub get
flutter run

# If packages conflict
flutter pub deps
```

### Getting Help

#### Check Logs
```bash
# Backend logs (if running in terminal)
# Check the terminal where uvicorn is running

# Docker logs
docker-compose logs postgres
docker-compose logs redis

# Container logs
docker logs restaurant-postgres
```

#### API Testing
- Use http://localhost:8000/docs for interactive API testing
- Test endpoints directly in the browser
- Check network requests in browser dev tools

#### Database Inspection
```bash
# Connect to database
docker exec -it restaurant-postgres psql -U postgres -d restaurant_ordering

# List tables
\dt

# Check data
SELECT * FROM restaurants;
SELECT * FROM users;
SELECT * FROM orders LIMIT 5;
```

## 🎉 Success Indicators

You'll know everything is working when:

✅ **Docker**: `docker ps` shows 2 containers running  
✅ **Backend**: http://localhost:8000/docs loads successfully  
✅ **Database**: Sample data exists (restaurant, menu, tables)  
✅ **Frontend**: Flutter app opens and shows QR scanner  
✅ **API**: Can browse menu and place orders  
✅ **Real-time**: Order updates work via WebSocket  

## 🚀 Next Steps

Once everything is working:

1. **Customize the Restaurant**: Update restaurant details, menu, and branding
2. **Configure Payments**: Add Stripe and M-Pesa credentials
3. **Set up Authentication**: Configure Supabase for user management
4. **Deploy**: Use the production Docker setup for deployment
5. **Monitor**: Set up logging and monitoring for production use

## 📞 Support

If you encounter issues:

1. **Check this guide** - Most common issues are covered
2. **Review logs** - Check backend and Docker logs for errors
3. **Test components individually** - Database, backend, frontend
4. **Check network connectivity** - Ensure ports are not blocked
5. **Verify prerequisites** - Ensure Docker and Flutter are properly installed

---

**🎊 Congratulations! Your restaurant ordering system is now ready to take orders!** 🍽️

