from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth import create_user, check_login
from app.database import get_db
from app.models import User, Food as FoodModel, UserFoodLog  # Updated imports
from app.schemas import FoodCreate, UserFood, UserFoodBase, UserProfile, FoodResponse  # Updated imports
from typing import List, Optional
from datetime import datetime


router = APIRouter()

# All Get routes
@router.get("/users/")
def read_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    try:
        # Make sure to order by a specific column, e.g., user_id
        users = db.query(User).order_by(User.user_id).offset(skip).limit(limit).all()
        return users
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@router.get("/foods/", response_model=List[FoodResponse])  # Use FoodSchema for response
def read_foods(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    try:
        foods = db.query(FoodModel).order_by(FoodModel.food_id).offset(skip).limit(limit).all()  # Use FoodModel for querying
        return foods  # This will be automatically converted to FoodSchema by FastAPI
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")
        
@router.get("/user-foods/{user_id}/logs", response_model=List[UserFood])
def get_user_food_logs(
    user_id: int,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db)
):
    try:
        # Start the query
        query = db.query(UserFoodLog).filter(UserFoodLog.user_id == user_id)

        # Add filters for dates if provided
        if start_date:
            query = query.filter(UserFoodLog.consumed_at >= start_date)
        if end_date:
            query = query.filter(UserFoodLog.consumed_at <= end_date)

        # Execute the query
        return query.all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

# All post routes
@router.post("/register/")
async def register_user(email: str, password: str, height: float, weight: float, age: int, gender: str, username: str, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    user = create_user(db, email, password, height, weight, age, gender, username)
    return {"message": "User registered successfully", "user_id": user.user_id}

@router.post("/login/")
async def login_user(email: str, password: str, db: Session = Depends(get_db)):
    try:
        if check_login(db, email, password):
            return {"message": "Login successful"}
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@router.post("/foods/", response_model=FoodResponse)  # Use FoodResponse for response
def create_food(food: FoodCreate, db: Session = Depends(get_db)):  # Accept FoodCreate as input
    db_food = FoodModel(**food.dict())  # Create FoodModel instance from FoodCreate
    db.add(db_food)
    db.commit()
    db.refresh(db_food)
    return db_food

# Log user food consumption
@router.post("/user-foods/", response_model=UserFood)
def create_user_food(user_food: UserFoodBase, db: Session = Depends(get_db)):
    db_user_food = UserFoodLog(**user_food.dict())
    db.add(db_user_food)
    db.commit()
    db.refresh(db_user_food)
    return db_user_food


# All delete routes
@router.delete("/foods/{food_id}", response_model=dict)
def delete_food(food_id: int, db: Session = Depends(get_db)):
    food_item = db.query(FoodModel).filter(FoodModel.food_id == food_id).first()
    if food_item is None:
        raise HTTPException(status_code=404, detail="Food not found")
    db.delete(food_item)
    db.commit()
    return {"message": "Food deleted successfully"}

@router.delete("/users/{user_id}", response_model=dict)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)  # This will cascade and delete the associated UserProfile
    db.commit()
    return {"message": "User and associated profile deleted successfully"}