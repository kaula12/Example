import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database import Base, get_db
from main import app
import models

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture
def test_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture
def test_user(test_db):
    user = models.User(
        email="test@example.com",
        full_name="Test User",
        phone="+254700000000",
        role=models.UserRole.CUSTOMER,
        is_active=True
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def test_restaurant(test_db):
    restaurant = models.Restaurant(
        name="Test Restaurant",
        description="A test restaurant",
        address="123 Test Street",
        phone="+254700000000",
        email="test@restaurant.com",
        is_active=True
    )
    test_db.add(restaurant)
    test_db.commit()
    test_db.refresh(restaurant)
    return restaurant

@pytest.fixture
def test_table(test_db, test_restaurant):
    table = models.Table(
        restaurant_id=test_restaurant.id,
        table_number="T001",
        qr_code="QR-TEST-001",
        capacity=4,
        is_active=True
    )
    test_db.add(table)
    test_db.commit()
    test_db.refresh(table)
    return table

def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Restaurant Table Ordering System API"
    assert data["version"] == "1.0.0"

def test_health_check():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_qr_code_scan(test_table):
    """Test QR code scanning"""
    response = client.get(f"/api/menu/qr/{test_table.qr_code}")
    assert response.status_code == 200
    data = response.json()
    assert data["table_id"] == test_table.id
    assert data["restaurant_id"] == test_table.restaurant_id
    assert data["table_number"] == test_table.table_number

def test_qr_code_scan_invalid():
    """Test QR code scanning with invalid code"""
    response = client.get("/api/menu/qr/INVALID-QR-CODE")
    assert response.status_code == 404

def test_get_menu(test_restaurant):
    """Test getting restaurant menu"""
    response = client.get(f"/api/menu/restaurant/{test_restaurant.id}")
    assert response.status_code == 200
    data = response.json()
    assert "categories" in data
    assert "items" in data
    assert isinstance(data["categories"], list)
    assert isinstance(data["items"], list)

def test_user_registration():
    """Test user registration"""
    user_data = {
        "email": "newuser@example.com",
        "full_name": "New User",
        "phone": "+254700000001",
        "role": "customer"
    }
    response = client.post("/api/auth/register", json=user_data)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == user_data["email"]
    assert data["full_name"] == user_data["full_name"]

def test_user_registration_duplicate_email(test_user):
    """Test user registration with duplicate email"""
    user_data = {
        "email": test_user.email,
        "full_name": "Another User",
        "phone": "+254700000002",
        "role": "customer"
    }
    response = client.post("/api/auth/register", json=user_data)
    assert response.status_code == 400

class TestOrderFlow:
    """Test the complete order flow"""
    
    def test_create_order_unauthorized(self, test_table):
        """Test creating order without authentication"""
        order_data = {
            "table_id": test_table.id,
            "items": [
                {
                    "menu_item_id": 1,
                    "quantity": 2,
                    "customizations": {},
                    "special_instructions": "No onions"
                }
            ]
        }
        response = client.post("/api/orders/", json=order_data)
        assert response.status_code == 401

    def test_get_orders_unauthorized(self):
        """Test getting orders without authentication"""
        response = client.get("/api/orders/")
        assert response.status_code == 401

if __name__ == "__main__":
    pytest.main([__file__])

