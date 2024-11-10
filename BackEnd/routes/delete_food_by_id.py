from fastapi import APIRouter
from database.database import get_db
from models.models import Food as FoodModel
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException

router = APIRouter()

@router.delete("/foods/{food_id}", response_model=dict)
def delete_food(food_id: int, db: Session = Depends(get_db)):
    food_item = db.query(FoodModel).filter(FoodModel.food_id == food_id).first()
    if food_item is None:
        raise HTTPException(status_code=404, detail="Food not found")
    db.delete(food_item)
    db.commit()
    return {"message": "Food deleted successfully"}