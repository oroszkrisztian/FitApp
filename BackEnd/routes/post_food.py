from fastapi import APIRouter
from database.database import get_db
from models.models import User, Food as FoodModel
from schemas.schemas import FoodCreate, FoodResponse, UserFood
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from routes.user_post_food import create_user_food

router = APIRouter()

@router.post("/foods/", response_model=UserFood)
def create_food(food: FoodCreate, user_id: int, grams: float, db: Session = Depends(get_db)):
    existing_food = db.query(FoodModel).filter(FoodModel.name.ilike(food.name.lower())).all()
    # Check if there's any existing food with the same name and others
    if existing_food:
        for item in existing_food:
            if (
                item.carbs == food.carbs and
                item.protein == food.protein and
                item.calories == food.calories and
                item.fat == food.fat
            ):
                return create_user_food(user_id=user_id, food_id=item.food_id, grams=grams, db=db)
    db_food = FoodModel(**food.dict())
    db.add(db_food)
    db.commit()
    db.refresh(db_food)
    return create_user_food(user_id=user_id, food_id=db_food.food_id, grams=grams, db=db)
