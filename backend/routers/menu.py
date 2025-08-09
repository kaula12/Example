from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from database import get_db
from models.restaurant import Restaurant
from models.menu import Category, MenuItem
from routers.auth import get_current_active_user
from models.user import User

router = APIRouter()

# Pydantic models
class MenuItemResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    price: float
    image_url: Optional[str]
    is_vegetarian: bool
    is_vegan: bool
    is_gluten_free: bool
    is_dairy_free: bool
    is_nut_free: bool
    is_available: bool
    preparation_time: int
    calories: Optional[int]
    ingredients: Optional[str]
    allergens: Optional[str]
    customization_options: Optional[dict]
    sort_order: int
    
    class Config:
        from_attributes = True

class CategoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    image_url: Optional[str]
    sort_order: int
    is_active: bool
    menu_items: List[MenuItemResponse] = []
    
    class Config:
        from_attributes = True

class RestaurantMenuResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    address: str
    phone: Optional[str]
    opening_hours: Optional[str]
    logo_url: Optional[str]
    cover_image_url: Optional[str]
    categories: List[CategoryResponse] = []
    
    class Config:
        from_attributes = True

# Routes
@router.get("/restaurant/{restaurant_id}", response_model=RestaurantMenuResponse)
async def get_restaurant_menu(restaurant_id: int, db: Session = Depends(get_db)):
    """Get complete menu for a restaurant"""
    restaurant = db.query(Restaurant).filter(
        Restaurant.id == restaurant_id,
        Restaurant.is_active == True
    ).first()
    
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    
    # Get categories with menu items
    categories = db.query(Category).filter(
        Category.restaurant_id == restaurant_id,
        Category.is_active == True
    ).order_by(Category.sort_order).all()
    
    # Load menu items for each category
    for category in categories:
        category.menu_items = db.query(MenuItem).filter(
            MenuItem.category_id == category.id,
            MenuItem.is_available == True
        ).order_by(MenuItem.sort_order, MenuItem.name).all()
    
    restaurant.categories = categories
    return restaurant

@router.get("/categories/{category_id}/items", response_model=List[MenuItemResponse])
async def get_category_items(
    category_id: int,
    db: Session = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """Get menu items for a specific category"""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    items = db.query(MenuItem).filter(
        MenuItem.category_id == category_id,
        MenuItem.is_available == True
    ).order_by(MenuItem.sort_order, MenuItem.name).offset(skip).limit(limit).all()
    
    return items

@router.get("/items/{item_id}", response_model=MenuItemResponse)
async def get_menu_item(item_id: int, db: Session = Depends(get_db)):
    """Get details of a specific menu item"""
    item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    
    if not item.is_available:
        raise HTTPException(status_code=404, detail="Menu item not available")
    
    return item

@router.get("/search")
async def search_menu_items(
    q: str = Query(..., min_length=2, description="Search query"),
    restaurant_id: Optional[int] = Query(None, description="Filter by restaurant"),
    category_id: Optional[int] = Query(None, description="Filter by category"),
    vegetarian: Optional[bool] = Query(None, description="Filter vegetarian items"),
    vegan: Optional[bool] = Query(None, description="Filter vegan items"),
    gluten_free: Optional[bool] = Query(None, description="Filter gluten-free items"),
    max_price: Optional[float] = Query(None, ge=0, description="Maximum price"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Search menu items with filters"""
    query = db.query(MenuItem).filter(MenuItem.is_available == True)
    
    # Text search
    if q:
        query = query.filter(
            MenuItem.name.ilike(f"%{q}%") | 
            MenuItem.description.ilike(f"%{q}%")
        )
    
    # Restaurant filter
    if restaurant_id:
        query = query.join(Category).filter(Category.restaurant_id == restaurant_id)
    
    # Category filter
    if category_id:
        query = query.filter(MenuItem.category_id == category_id)
    
    # Dietary filters
    if vegetarian is not None:
        query = query.filter(MenuItem.is_vegetarian == vegetarian)
    
    if vegan is not None:
        query = query.filter(MenuItem.is_vegan == vegan)
    
    if gluten_free is not None:
        query = query.filter(MenuItem.is_gluten_free == gluten_free)
    
    # Price filter
    if max_price is not None:
        query = query.filter(MenuItem.price <= max_price)
    
    # Execute query
    items = query.order_by(MenuItem.name).offset(skip).limit(limit).all()
    
    return {
        "items": items,
        "total": query.count(),
        "skip": skip,
        "limit": limit
    }

@router.get("/categories", response_model=List[CategoryResponse])
async def get_categories(
    restaurant_id: Optional[int] = Query(None, description="Filter by restaurant"),
    db: Session = Depends(get_db)
):
    """Get all categories, optionally filtered by restaurant"""
    query = db.query(Category).filter(Category.is_active == True)
    
    if restaurant_id:
        query = query.filter(Category.restaurant_id == restaurant_id)
    
    categories = query.order_by(Category.sort_order, Category.name).all()
    return categories

@router.get("/popular")
async def get_popular_items(
    restaurant_id: Optional[int] = Query(None, description="Filter by restaurant"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Get popular menu items (placeholder - would need order analytics)"""
    # This is a simplified version - in production you'd analyze order data
    query = db.query(MenuItem).filter(MenuItem.is_available == True)
    
    if restaurant_id:
        query = query.join(Category).filter(Category.restaurant_id == restaurant_id)
    
    # For now, just return items ordered by price (as a placeholder for popularity)
    items = query.order_by(MenuItem.price.desc()).limit(limit).all()
    
    return {
        "items": items,
        "message": "Popular items (demo data)"
    }

@router.get("/dietary-options")
async def get_dietary_options(
    restaurant_id: Optional[int] = Query(None, description="Filter by restaurant"),
    db: Session = Depends(get_db)
):
    """Get available dietary options summary"""
    query = db.query(MenuItem).filter(MenuItem.is_available == True)
    
    if restaurant_id:
        query = query.join(Category).filter(Category.restaurant_id == restaurant_id)
    
    items = query.all()
    
    summary = {
        "vegetarian_count": sum(1 for item in items if item.is_vegetarian),
        "vegan_count": sum(1 for item in items if item.is_vegan),
        "gluten_free_count": sum(1 for item in items if item.is_gluten_free),
        "dairy_free_count": sum(1 for item in items if item.is_dairy_free),
        "nut_free_count": sum(1 for item in items if item.is_nut_free),
        "total_items": len(items)
    }
    
    return summary

