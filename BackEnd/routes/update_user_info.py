from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.database import get_db
from models.models import User, UserProfile, UserRecommended
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
    activity: int = None,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.user_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    # Update User table fields
    if email is not None:
        user.email = email
    if password is not None:
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        user.password = hashed_password.decode('utf-8')

    # Update User_profiles table
    user_profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if user_profile is None:
        raise HTTPException(status_code=404, detail="User profile not found")

    # Use current values if not provided in the request
    if height is None:
        height = float(user_profile.height)
    else:
        user_profile.height = height
    if weight is None:
        weight = float(user_profile.weight)
    else:
        user_profile.weight = weight
    if age is None:
        age = user_profile.age
    else:
        user_profile.age = age
    if gender is None:
        gender = user_profile.gender
    else:
        user_profile.gender = gender
    if activity is None:
        activity = user_profile.activity
    else:
        user_profile.activity = activity

    user_recommended = db.query(UserRecommended).filter(UserRecommended.user_id == user_id).first()
    if user_recommended is None:
        user_recommended = UserRecommended(user_id=user_id)
        db.add(user_recommended)

    # Calculate BMR based on gender
    if gender.lower() == "male":
        bmr = 10 * float(weight) + 6.25 * float(height) - 5 * age + 5
    else:
        bmr = 10 * float(weight) + 6.25 * float(height) - 5 * age - 161

    # Adjust BMR based on activity level
    activity_multiplier = {1: 1.2, 2: 1.375, 3: 1.55, 4: 1.725, 5: 1.9}
    bmr *= activity_multiplier.get(activity, 1.2)  # Default to 1.2 if invalid activity

    # Calculate macronutrient recommendations
    user_recommended.calorie = float(round(bmr))
    user_recommended.protein = float(round(bmr * 0.2 / 6))
    user_recommended.fat = float(round(bmr * 0.25 / 9))
    user_recommended.carbs = float(round(bmr * 0.55 / 6))

    # Commit changes to the database
    db.commit()

    return {"message": "User information and recommendations updated successfully"}
