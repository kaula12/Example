#!/usr/bin/env python3
"""
Seed script to populate the database with sample data for testing
"""

import sys
import os
from datetime import datetime, timedelta
import uuid
from sqlalchemy.orm import Session

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal, engine
from models import *
from passlib.context import CryptContext

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def create_sample_data():
    """Create sample data for the restaurant ordering system"""
    db = SessionLocal()
    
    try:
        print("🌱 Starting database seeding...")
        
        # Check if data already exists
        if db.query(Restaurant).first():
            print("⚠️  Sample data already exists. Skipping seeding.")
            return
        
        # 1. Create Restaurant
        print("📍 Creating restaurant...")
        restaurant = Restaurant(
            name="Savory Delights Restaurant",
            description="Experience authentic flavors with our carefully crafted dishes made from the finest ingredients.",
            address="123 Foodie Street, Nairobi, Kenya",
            phone="+254712345678",
            email="info@savorydelights.co.ke",
            website="https://savorydelights.co.ke",
            opening_hours='{"monday": "9:00-22:00", "tuesday": "9:00-22:00", "wednesday": "9:00-22:00", "thursday": "9:00-22:00", "friday": "9:00-23:00", "saturday": "9:00-23:00", "sunday": "10:00-21:00"}',
            latitude=-1.2921,
            longitude=36.8219,
            is_active=True,
            accepts_online_orders=True,
            delivery_available=True,
            pickup_available=True,
            logo_url="https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=200",
            cover_image_url="https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800"
        )
        db.add(restaurant)
        db.commit()
        db.refresh(restaurant)
        
        # 2. Create Tables
        print("🪑 Creating tables...")
        tables_data = [
            {"number": "T01", "capacity": 2, "location": "Window side"},
            {"number": "T02", "capacity": 4, "location": "Main dining"},
            {"number": "T03", "capacity": 4, "location": "Main dining"},
            {"number": "T04", "capacity": 6, "location": "Family section"},
            {"number": "T05", "capacity": 2, "location": "Patio"},
            {"number": "T06", "capacity": 4, "location": "Patio"},
            {"number": "T07", "capacity": 8, "location": "Private dining"},
            {"number": "T08", "capacity": 4, "location": "Bar area"},
        ]
        
        for table_data in tables_data:
            table = Table(
                restaurant_id=restaurant.id,
                table_number=table_data["number"],
                qr_code=f"QR_{restaurant.id}_{table_data['number']}_{uuid.uuid4().hex[:8]}",
                capacity=table_data["capacity"],
                location=table_data["location"],
                is_active=True,
                is_occupied=False
            )
            db.add(table)
        
        db.commit()
        
        # 3. Create Users
        print("👥 Creating users...")
        users_data = [
            {
                "email": "admin@savorydelights.co.ke",
                "full_name": "Restaurant Admin",
                "phone": "+254712345678",
                "role": "admin",
                "password": "admin123"
            },
            {
                "email": "kitchen@savorydelights.co.ke", 
                "full_name": "Kitchen Manager",
                "phone": "+254712345679",
                "role": "kitchen",
                "password": "kitchen123"
            },
            {
                "email": "waiter@savorydelights.co.ke",
                "full_name": "Head Waiter",
                "phone": "+254712345680", 
                "role": "waiter",
                "password": "waiter123"
            },
            {
                "email": "customer@example.com",
                "full_name": "John Doe",
                "phone": "+254712345681",
                "role": "customer", 
                "password": "customer123"
            }
        ]
        
        for user_data in users_data:
            user = User(
                email=user_data["email"],
                full_name=user_data["full_name"],
                phone=user_data["phone"],
                hashed_password=hash_password(user_data["password"]),
                role=user_data["role"],
                is_active=True,
                is_verified=True
            )
            db.add(user)
        
        db.commit()
        
        # 4. Create Categories
        print("📂 Creating menu categories...")
        categories_data = [
            {
                "name": "Starters & Appetizers",
                "description": "Delicious appetizers to start your meal",
                "image_url": "https://images.unsplash.com/photo-1541014741259-de529411b96a?w=400",
                "sort_order": 1
            },
            {
                "name": "Main Courses", 
                "description": "Hearty main dishes to satisfy your hunger",
                "image_url": "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400",
                "sort_order": 2
            },
            {
                "name": "Grilled & BBQ",
                "description": "Perfectly grilled meats and vegetables",
                "image_url": "https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400", 
                "sort_order": 3
            },
            {
                "name": "Vegetarian & Vegan",
                "description": "Plant-based options full of flavor",
                "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
                "sort_order": 4
            },
            {
                "name": "Desserts",
                "description": "Sweet treats to end your meal perfectly", 
                "image_url": "https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400",
                "sort_order": 5
            },
            {
                "name": "Beverages",
                "description": "Refreshing drinks and specialty beverages",
                "image_url": "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400",
                "sort_order": 6
            }
        ]
        
        categories = []
        for cat_data in categories_data:
            category = Category(
                restaurant_id=restaurant.id,
                name=cat_data["name"],
                description=cat_data["description"],
                image_url=cat_data["image_url"],
                sort_order=cat_data["sort_order"],
                is_active=True
            )
            db.add(category)
            categories.append(category)
        
        db.commit()
        
        # 5. Create Menu Items
        print("🍽️ Creating menu items...")
        
        # Starters & Appetizers
        starters_items = [
            {
                "name": "Crispy Chicken Wings",
                "description": "Juicy chicken wings with your choice of sauce",
                "price": 850.00,
                "image_url": "https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400",
                "preparation_time": 15,
                "customization_options": {
                    "sauce": ["BBQ", "Buffalo", "Honey Garlic", "Plain"],
                    "spice_level": ["Mild", "Medium", "Hot", "Extra Hot"]
                }
            },
            {
                "name": "Loaded Nachos",
                "description": "Crispy tortilla chips topped with cheese, jalapeños, and sour cream",
                "price": 750.00,
                "image_url": "https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400",
                "preparation_time": 10,
                "is_vegetarian": True
            },
            {
                "name": "Samosa Platter",
                "description": "Traditional crispy pastries filled with spiced vegetables",
                "price": 450.00,
                "image_url": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400",
                "preparation_time": 8,
                "is_vegetarian": True,
                "is_vegan": True
            }
        ]
        
        # Main Courses
        main_courses = [
            {
                "name": "Grilled Chicken Breast",
                "description": "Tender grilled chicken served with roasted vegetables and mashed potatoes",
                "price": 1250.00,
                "image_url": "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=400",
                "preparation_time": 25,
                "is_gluten_free": True,
                "customization_options": {
                    "cooking": ["Well Done", "Medium", "Medium Rare"],
                    "side": ["Mashed Potatoes", "Rice", "Fries", "Salad"]
                }
            },
            {
                "name": "Beef Stir Fry",
                "description": "Tender beef strips with fresh vegetables in savory sauce",
                "price": 1350.00,
                "image_url": "https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400",
                "preparation_time": 20
            },
            {
                "name": "Fish & Chips",
                "description": "Beer-battered fish with crispy fries and tartar sauce",
                "price": 1150.00,
                "image_url": "https://images.unsplash.com/photo-1544982503-9f984c14501a?w=400",
                "preparation_time": 18
            }
        ]
        
        # Grilled & BBQ
        grilled_items = [
            {
                "name": "BBQ Ribs",
                "description": "Slow-cooked pork ribs with our signature BBQ sauce",
                "price": 1650.00,
                "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?w=400",
                "preparation_time": 35
            },
            {
                "name": "Grilled Salmon",
                "description": "Fresh Atlantic salmon grilled to perfection",
                "price": 1850.00,
                "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400",
                "preparation_time": 20,
                "is_gluten_free": True
            }
        ]
        
        # Vegetarian & Vegan
        veg_items = [
            {
                "name": "Quinoa Buddha Bowl",
                "description": "Nutritious bowl with quinoa, roasted vegetables, and tahini dressing",
                "price": 950.00,
                "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
                "preparation_time": 15,
                "is_vegetarian": True,
                "is_vegan": True,
                "is_gluten_free": True
            },
            {
                "name": "Margherita Pizza",
                "description": "Classic pizza with fresh tomatoes, mozzarella, and basil",
                "price": 1050.00,
                "image_url": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400",
                "preparation_time": 22,
                "is_vegetarian": True
            }
        ]
        
        # Desserts
        desserts = [
            {
                "name": "Chocolate Lava Cake",
                "description": "Warm chocolate cake with molten center, served with vanilla ice cream",
                "price": 650.00,
                "image_url": "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400",
                "preparation_time": 12,
                "is_vegetarian": True
            },
            {
                "name": "Tiramisu",
                "description": "Classic Italian dessert with coffee-soaked ladyfingers and mascarpone",
                "price": 550.00,
                "image_url": "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400",
                "preparation_time": 5,
                "is_vegetarian": True
            }
        ]
        
        # Beverages
        beverages = [
            {
                "name": "Fresh Orange Juice",
                "description": "Freshly squeezed orange juice",
                "price": 250.00,
                "image_url": "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400",
                "preparation_time": 3,
                "is_vegetarian": True,
                "is_vegan": True
            },
            {
                "name": "Cappuccino",
                "description": "Rich espresso with steamed milk and foam",
                "price": 300.00,
                "image_url": "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400",
                "preparation_time": 5,
                "is_vegetarian": True
            },
            {
                "name": "Craft Beer",
                "description": "Local craft beer selection",
                "price": 450.00,
                "image_url": "https://images.unsplash.com/photo-1608270586620-248524c67de9?w=400",
                "preparation_time": 2
            }
        ]
        
        # Add all menu items
        all_items = [
            (starters_items, 0),  # Starters category index
            (main_courses, 1),    # Main courses category index
            (grilled_items, 2),   # Grilled category index
            (veg_items, 3),       # Vegetarian category index
            (desserts, 4),        # Desserts category index
            (beverages, 5)        # Beverages category index
        ]
        
        for items, category_index in all_items:
            for item_data in items:
                menu_item = MenuItem(
                    category_id=categories[category_index].id,
                    name=item_data["name"],
                    description=item_data["description"],
                    price=item_data["price"],
                    image_url=item_data["image_url"],
                    preparation_time=item_data.get("preparation_time", 15),
                    is_vegetarian=item_data.get("is_vegetarian", False),
                    is_vegan=item_data.get("is_vegan", False),
                    is_gluten_free=item_data.get("is_gluten_free", False),
                    is_dairy_free=item_data.get("is_dairy_free", False),
                    is_nut_free=item_data.get("is_nut_free", False),
                    is_available=True,
                    customization_options=item_data.get("customization_options"),
                    sort_order=0
                )
                db.add(menu_item)
        
        db.commit()
        
        # 6. Create Sample Order
        print("📋 Creating sample order...")
        sample_table = db.query(Table).filter(Table.table_number == "T01").first()
        sample_customer = db.query(User).filter(User.role == "customer").first()
        
        if sample_table and sample_customer:
            order = Order(
                restaurant_id=restaurant.id,
                table_id=sample_table.id,
                customer_id=sample_customer.id,
                order_number=f"ORD-{datetime.now().strftime('%Y%m%d')}-001",
                status="pending",
                subtotal=1100.00,
                tax_amount=176.00,  # 16% VAT
                service_charge=110.00,  # 10% service charge
                discount_amount=0.00,
                total_amount=1386.00,
                payment_method="mpesa",
                payment_status="pending",
                customer_name=sample_customer.full_name,
                customer_phone=sample_customer.phone,
                customer_email=sample_customer.email,
                special_instructions="Please make it spicy",
                estimated_preparation_time=25
            )
            db.add(order)
            db.commit()
            db.refresh(order)
            
            # Add order items
            chicken_wings = db.query(MenuItem).filter(MenuItem.name == "Crispy Chicken Wings").first()
            cappuccino = db.query(MenuItem).filter(MenuItem.name == "Cappuccino").first()
            
            if chicken_wings:
                order_item1 = OrderItem(
                    order_id=order.id,
                    menu_item_id=chicken_wings.id,
                    quantity=1,
                    unit_price=chicken_wings.price,
                    total_price=chicken_wings.price,
                    customizations={"sauce": "Buffalo", "spice_level": "Hot"},
                    status="pending"
                )
                db.add(order_item1)
            
            if cappuccino:
                order_item2 = OrderItem(
                    order_id=order.id,
                    menu_item_id=cappuccino.id,
                    quantity=1,
                    unit_price=cappuccino.price,
                    total_price=cappuccino.price,
                    status="pending"
                )
                db.add(order_item2)
            
            db.commit()
        
        # 7. Create Sample Service Request
        print("🔔 Creating sample service request...")
        if sample_table and sample_customer:
            service_request = ServiceRequest(
                table_id=sample_table.id,
                customer_id=sample_customer.id,
                request_type="water",
                message="Please bring water to our table",
                priority=2,
                status="pending"
            )
            db.add(service_request)
            db.commit()
        
        print("✅ Database seeding completed successfully!")
        print(f"📊 Created:")
        print(f"   • 1 Restaurant: {restaurant.name}")
        print(f"   • {len(tables_data)} Tables")
        print(f"   • {len(users_data)} Users")
        print(f"   • {len(categories_data)} Categories")
        print(f"   • ~20 Menu Items")
        print(f"   • 1 Sample Order")
        print(f"   • 1 Sample Service Request")
        print()
        print("🎉 Your restaurant is ready to take orders!")
        print("📱 Use QR codes from tables to test the ordering system")
        
    except Exception as e:
        print(f"❌ Error during seeding: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    create_sample_data()

