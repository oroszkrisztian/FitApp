from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.database import get_db
from models.models import User, UserProfile,UserRecommended  # Assuming UserProfile is the model for User_profiles
import bcrypt

router = APIRouter()

@router.put("/update/{user_id}", response_model=dict)
def update_user_info(
    user_id: int,
    email: str = None,
    password: str = None,
    height: float = None,
    weight: float = None,
    age: int = None,
    gender: str = None,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.user_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    # Update User table fields1
    if email is not None:
        user.email = email
    if password is not None:
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        user.password = hashed_password.decode('utf-8')

    # Update User_profiles table (if exists)
    user_profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if user_profile:
        if height is not None:
            user_profile.height = height
        if weight is not None:
            user_profile.weight = weight
        if age is not None:
            user_profile.age = age
        if gender is not None:
            user_profile.gender = gender

    user_recommended = db.query(UserRecommended).filter(UserRecommended.user_id == user_id).first()
    if user_recommended is None:
        user_recommended = UserRecommended(user_id=user_id)
        db.add(user_recommended)

    # Calculate and update UserRecommended values
    if height is not None and weight is not None and age is not None and gender is not None:
        # Calculate BMR based on gender
        if gender.lower() == "male":
            bmr = 10 * weight + 6.25 * height - 5 * age + 5
        else:
            bmr = 10 * weight + 6.25 * height - 5 * age - 161

        # Calculate macronutrient recommendations
        user_recommended.calorie = float(round(bmr))
        user_recommended.protein = float(round(bmr * 0.2 / 6))
        user_recommended.fat = float(round(bmr * 0.25 / 9))
        user_recommended.carbs = float(round(bmr * 0.55 / 6))

    # Commit changes to the database
    db.commit()

    return {"message": "User information and recommendations updated successfully"}
