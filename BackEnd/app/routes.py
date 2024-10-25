from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth import create_user, check_login
from app.database import get_db
from app.models import User, Food as FoodModel, UserFood as UserFoodModel  # SQLAlchemy modellek
from app.schemas import Food, UserFood  # Pydantic sémák
from typing import List


router = APIRouter()

@router.get("/users/")
def read_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return users

# Register route
@router.post("/register/")
async def register_user(email: str, password: str, height: float, weight: float, age: int, gender: str, db: Session = Depends(get_db)):
    # Check if user already exists
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = create_user(db, email, password, height, weight, age, gender)
    return {"message": "User registered successfully", "user_id": user.user_id}

# Login route
@router.post("/login/")
async def login_user(email: str, password: str, db: Session = Depends(get_db)):
    if check_login(db, email, password):
        return {"message": "Login successful"}
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
# Foods GET route
@router.get("/foods/", response_model=List[Food])
def read_foods(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    foods = db.query(FoodModel).offset(skip).limit(limit).all()
    return foods

# Foods POST route
@router.post("/foods/", response_model=Food)
def create_food(food: Food, db: Session = Depends(get_db)):
    db_food = FoodModel(**food.dict())
    db.add(db_food)
    db.commit()
    db.refresh(db_food)
    return db_food

# Route to track user food consumption
@router.post("/user-foods/", response_model=UserFood)
def create_user_food(user_food: UserFood, db: Session = Depends(get_db)):
    db_user_food = UserFoodModel(**user_food.dict())
    db.add(db_user_food)
    db.commit()
    db.refresh(db_user_food)
    return db_user_food
