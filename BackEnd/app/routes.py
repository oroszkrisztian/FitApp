from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth import create_user, check_login
from app.database import get_db
from app.models import User

router = APIRouter()

# Register route
@router.post("/register/")
async def register_user(email: str, password: str, height: float, weight: float, age: int, gender: str, db: Session = Depends(get_db)):
    # Check if user already exists
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = create_user(db, email, password, height, weight, age, gender)
    return {"message": "User registered successfully", "user_id": user.user_id}

# Login route
@router.post("/login/")
async def login_user(email: str, password: str, db: Session = Depends(get_db)):
    if check_login(db, email, password):
        return {"message": "Login successful"}
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")