from fastapi import APIRouter
from database.database import get_db
from models.models import Food as FoodModel
from schemas.schemas import FoodResponse
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from typing import List

router = APIRouter()

@router.get("/foods/", response_model=List[FoodResponse])  # Use FoodSchema for response
def read_foods(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    try:
        foods = db.query(FoodModel).order_by(FoodModel.food_id).offset(skip).limit(limit).all()  # Use FoodModel for querying
        return foods
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")