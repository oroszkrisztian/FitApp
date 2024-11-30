from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.database import get_db
from models.models import UserRecommended
from schemas.schemas import UserRecommendedResponse

router = APIRouter()

@router.get("/user/{user_id}/recommended", response_model=UserRecommendedResponse)
def get_user_recommended(user_id: int, db: Session = Depends(get_db)):
    recommended_data = db.query(UserRecommended).filter(UserRecommended.user_id == user_id).first()
    if not recommended_data:
        raise HTTPException(status_code=404, detail="Recommended data not found for this user")   
    return recommended_data