from fastapi import APIRouter
from database.database import get_db
from models.models import UserFoodLog
from schemas.schemas import UserFoodBase, UserFood
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from datetime import date

router = APIRouter()

@router.post("/user-foods/", response_model=UserFood)
def create_user_food(user_id=int, food_id=int, grams=float, db: Session = Depends(get_db)):
    user_food=UserFoodBase(user_id=user_id, food_id=food_id, grams=grams, consumed_at=date.today())
    db_user_food = UserFoodLog(**user_food.dict())
    db.add(db_user_food)
    db.commit()
    db.refresh(db_user_food)
    return db_user_food