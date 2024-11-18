from fastapi import APIRouter
from database.database import get_db
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from models.models import UserProfile
from schemas.schemas import UserProfileResponse

router = APIRouter()

@router.get("/users/{user_id}", response_model=UserProfileResponse)
def get_user_info(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user