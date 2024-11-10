from fastapi import APIRouter
from database.database import get_db
from models.models import User
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from auth.auth import create_user

router = APIRouter()

@router.post("/register/")
async def register_user(email: str, password: str, height: float, weight: float, age: int, gender: str, username: str, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    user = create_user(db, email, password, height, weight, age, gender, username)
    return {"message": "User registered successfully", "user_id": user.user_id}