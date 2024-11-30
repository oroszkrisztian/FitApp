from fastapi import APIRouter
from database.database import get_db
from models.models import UserFoodLog, Food
from schemas.schemas import UserFoodLogResponse
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from typing import List, Optional
from datetime import date

router = APIRouter()

@router.get("/user-foods/{user_id}", response_model=List[UserFoodLogResponse])
def get_user_food_logs(
    user_id: int,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: Session = Depends(get_db)
):
    try:
        # Start the query with a join to the Food table
        query = (
            db.query(UserFoodLog)
            .join(Food, UserFoodLog.food_id == Food.food_id)
            .filter(UserFoodLog.user_id == user_id)
        )

        # Add filters for dates if provided
        if start_date:
            query = query.filter(UserFoodLog.consumed_at >= start_date)
        if end_date:
            query = query.filter(UserFoodLog.consumed_at <= end_date)

        # Execute the query and return results
        return query.all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")
