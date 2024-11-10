from fastapi import APIRouter
from database.database import get_db
from models.models import User
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException

router = APIRouter()

@router.get("/users/")
def read_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    try:
        users = db.query(User).order_by(User.user_id).offset(skip).limit(limit).all()
        return users
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")