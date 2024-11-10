from fastapi import APIRouter
from database.database import get_db
from models.models import UserFoodLog
from schemas.schemas import UserFoodBase, UserFood
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException

router = APIRouter()

@router.post("/user-foods/", response_model=UserFood)
def create_user_food(user_food: UserFoodBase, db: Session = Depends(get_db)):
    db_user_food = UserFoodLog(**user_food.dict())
    db.add(db_user_food)
    db.commit()
    db.refresh(db_user_food)
    return db_user_food