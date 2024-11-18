from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.database import get_db
from models.models import User, UserProfile  # Assuming UserProfile is the model for User_profiles
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

    # Update User table fields
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

    # Commit the changes
    db.commit()
    return {"message": "User information updated successfully"}
