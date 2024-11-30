from fastapi import APIRouter
from database.database import get_db
from models.models import User, UserRecommended
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from auth.auth import create_user

router = APIRouter()

@router.post("/register/")
async def register_user(email: str, password: str, height: float, weight: float, age: int, gender: str, username: str, activity: int, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    user = create_user(db, email, password, height, weight, age, gender, username,activity)
    bmr=(10*weight+6.25*height-5*age+(5 if gender=='male' else -161))
    if activity == 1:
        bmr *= 1.2
    elif activity == 2:
        bmr *= 1.375
    elif activity == 3:
        bmr *= 1.55
    elif activity == 4:
        bmr *= 1.725
    elif activity == 5:
        bmr *= 1.9
    calories = float(round(bmr))  # Rounds to the nearest whole number and keeps float type
    protein = float(round(bmr * 0.2 / 6))
    fat = float(round(calories * 0.25 / 9))
    carbs = float(round(calories * 0.55 / 6))
    recommended_values = UserRecommended(
        user_id=user.user_id,
        calorie=calories,
        protein=protein,
        fat=fat,
        carbs=carbs
    )
    db.add(recommended_values)
    db.commit()
    return {"message": "User registered successfully", "user_id": user.user_id} 