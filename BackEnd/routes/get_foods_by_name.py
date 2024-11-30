from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from models.models import Food as FoodModel
from schemas.schemas import FoodDetails
from database.database import get_db
from typing import List

router = APIRouter()

@router.get("/foods/search/", response_model=List[FoodDetails])
def search_foods(name: str, db: Session = Depends(get_db)):
    try:
        # Query the database for foods whose names start with the input (case-insensitive)
        foods = db.query(FoodModel).filter(FoodModel.name.ilike(f"{name}%")).all()
        
        if not foods:
            raise HTTPException(status_code=404, detail="No matching foods found")
        
        return foods
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")