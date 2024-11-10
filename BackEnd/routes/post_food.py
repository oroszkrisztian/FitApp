from fastapi import APIRouter
from database.database import get_db
from models.models import User, Food as FoodModel
from schemas.schemas import FoodCreate, FoodResponse
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException

router = APIRouter()

@router.post("/foods/", response_model=FoodResponse)  # Use FoodResponse for response
def create_food(food: FoodCreate, db: Session = Depends(get_db)):  # Accept FoodCreate as input
    db_food = FoodModel(**food.dict())  # Create FoodModel instance from FoodCreate
    db.add(db_food)
    db.commit()
    db.refresh(db_food)
    return db_food