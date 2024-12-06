from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.database import get_db
from models.models import User, Food as FoodModel
from schemas.schemas import FoodCreate, FoodResponse, UserFood
from routes.user_post_food import create_user_food

router = APIRouter()

@router.post("/foods/", response_model=UserFood)
def create_food(food: FoodCreate, user_id: int, user_grams: float, db: Session = Depends(get_db)):
    existing_food = db.query(FoodModel).filter(FoodModel.name.ilike(food.name.lower())).all()

    # Check if there's any existing food with the same name
    if existing_food:
        return create_user_food(user_id=user_id, food_id=existing_food[0].food_id, grams=user_grams, db=db)

    # Create and add the new food to the database
    db_food = FoodModel(
        name=food.name,
        calories=food.calories,
        protein=food.protein,
        fat=food.fat,
        carbs=food.carbs
    )
    db.add(db_food)
    db.commit()
    db.refresh(db_food)

    # Create a UserFood entry
    return create_user_food(user_id=user_id, food_id=db_food.food_id, grams=user_grams, db=db)
