from fastapi import APIRouter
from database.database import get_db
from models.models import UserFoodLog
from schemas.schemas import UserFood
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from typing import List, Optional
from datetime import datetime

router = APIRouter()

@router.get("/user-foods/{user_id}", response_model=List[UserFood])
def get_user_food_logs(
    user_id: int,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db)
):
    try:
        # Start the query
        query = db.query(UserFoodLog).filter(UserFoodLog.user_id == user_id)

        # Add filters for dates if provided
        if start_date:
            query = query.filter(UserFoodLog.consumed_at >= start_date)
        if end_date:
            query = query.filter(UserFoodLog.consumed_at <= end_date)

        # Execute the query
        return query.all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")