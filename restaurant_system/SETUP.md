# Restaurant Ordering System - Setup Guide

This guide will walk you through setting up the complete restaurant ordering system with Flutter frontend, FastAPI backend, Supabase database, and Firebase integration.

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **Python 3.8+** with pip
- **Flutter SDK 3.10+**
- **Git**
- **Node.js** (for Firebase CLI)
- **Code editor** (VS Code recommended)

## 🔧 Step 1: Clone and Setup Project

```bash
# Clone the repository
git clone <repository-url>
cd restaurant_system

# Create backend virtual environment
cd backend
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Go back to project root
cd ..
```

## 🗄️ Step 2: Supabase Database Setup

### 2.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up/Login and create a new project
3. Wait for the project to be ready (2-3 minutes)
4. Note down your project URL and anon key

### 2.2 Setup Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Copy the contents of `database/supabase_schema.sql`
3. Paste and run the SQL script
4. Verify tables are created in the **Table Editor**

### 2.3 Configure Environment Variables

```bash
cd backend
cp .env.example .env
```

Edit `.env` file:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-anon-key-here
FIREBASE_PROJECT_ID=your-firebase-project-id
```

## 🔥 Step 3: Firebase Setup

### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Enter project name and follow setup steps
4. Enable Google Analytics (optional)

### 3.2 Enable Firebase Services

1. **Authentication**:
   - Go to Authentication → Sign-in method
   - Enable Email/Password (for future use)

2. **Cloud Messaging**:
   - Go to Project Settings → Cloud Messaging
   - Note down the Server Key

### 3.3 Generate Service Account Key

1. Go to Project Settings → Service accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Rename it to `firebase-service-account.json`
5. Place it in the `backend/` directory

### 3.4 Add Firebase to Flutter App

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Configure Flutter app:
```bash
cd frontend
firebase init
# Select your Firebase project
# Choose Flutter platform
```

## 📱 Step 4: Flutter Frontend Setup

### 4.1 Install Dependencies

```bash
cd frontend
flutter pub get
```

### 4.2 Configure App Settings

Edit `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Update with your backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  // Update with your Supabase credentials
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // Update with your Firebase project ID
  static const String firebaseProjectId = 'your-firebase-project-id';
}
```

### 4.3 Platform-specific Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Already configured with necessary permissions
- Update package name if needed

**iOS** (`ios/Runner/Info.plist`):
- Already configured with camera permissions
- Update bundle identifier if needed

## 🚀 Step 5: Running the Application

### 5.1 Start Backend Server

```bash
cd backend
# Make sure virtual environment is activated
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The backend will be available at: `http://localhost:8000`
API documentation: `http://localhost:8000/docs`

### 5.2 Run Flutter App

```bash
cd frontend
flutter run
```

For specific platforms:
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome
```

## 🧪 Step 6: Testing the System

### 6.1 Verify Backend

1. Open `http://localhost:8000/docs` in your browser
2. Test the `/health` endpoint
3. Try the `/api/menu` endpoint to see sample data

### 6.2 Test Flutter App

1. Launch the app on your device/emulator
2. Navigate through different roles:
   - Customer → Table Selection → Menu
   - Waiter → Dashboard
   - Kitchen → Dashboard
   - Admin → Dashboard

### 6.3 Test Real-time Features

1. Place an order as a customer
2. Check kitchen dashboard for new order
3. Update order status in kitchen
4. Verify status updates in customer order tracking

## 🔧 Step 7: Configuration for Production

### 7.1 Backend Production Setup

1. **Environment Variables**:
```env
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_KEY=your-prod-anon-key
FIREBASE_PROJECT_ID=your-prod-firebase-project
```

2. **Deploy Backend**:
   - Use platforms like Heroku, Railway, or AWS
   - Set environment variables in your deployment platform
   - Update CORS origins for your domain

### 7.2 Frontend Production Setup

1. **Update API Base URL**:
```dart
static const String baseUrl = 'https://your-api-domain.com';
```

2. **Build for Production**:
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🔍 Troubleshooting

### Common Issues

1. **Backend won't start**:
   - Check Python version: `python --version`
   - Verify virtual environment is activated
   - Check if all dependencies installed: `pip list`

2. **Flutter build errors**:
   - Run `flutter doctor` to check setup
   - Clear cache: `flutter clean && flutter pub get`
   - Check Flutter version: `flutter --version`

3. **Database connection issues**:
   - Verify Supabase URL and key in `.env`
   - Check if database schema was applied correctly
   - Test connection in Supabase dashboard

4. **Firebase notifications not working**:
   - Verify Firebase project configuration
   - Check service account key placement
   - Ensure FCM is enabled in Firebase console

### Debug Mode

Enable debug logging:

**Backend**:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Flutter**:
```bash
flutter run --verbose
```

## 📊 Sample Data

The system comes with sample data including:
- 10 menu items across 6 categories
- 10 restaurant tables
- Sample orders for testing

To reset sample data:
1. Go to Supabase dashboard
2. Run the schema SQL again (it will recreate tables)

## 🔐 Security Checklist

- [ ] Environment variables configured
- [ ] Firebase service account key secured
- [ ] Supabase RLS policies configured (optional)
- [ ] CORS properly configured for production
- [ ] API rate limiting implemented (for production)

## 📱 Mobile Testing

### Android Testing
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Build and install APK
flutter build apk
flutter install
```

### iOS Testing (macOS only)
```bash
# Open iOS Simulator
open -a Simulator

# Run on iOS
flutter run -d ios
```

## 🚀 Next Steps

After successful setup:

1. **Customize the app**:
   - Update branding and colors in `app_theme.dart`
   - Add your restaurant's menu items
   - Configure table layout

2. **Add features**:
   - QR code generation for tables
   - Advanced payment integrations
   - Customer authentication
   - Inventory management

3. **Deploy to production**:
   - Set up CI/CD pipeline
   - Configure monitoring and logging
   - Set up backup strategies

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review the API documentation at `/docs`
3. Check Flutter and Firebase documentation
4. Create an issue in the repository

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)

---

**🎉 Congratulations! Your restaurant ordering system is now ready to use!**

