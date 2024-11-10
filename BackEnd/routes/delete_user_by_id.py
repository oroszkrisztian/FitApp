from fastapi import APIRouter
from database.database import get_db
from models.models import User
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException

router = APIRouter()

@router.delete("/users/{user_id}", response_model=dict)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)  # This will cascade and delete the associated UserProfile
    db.commit()
    return {"message": "User and associated profile deleted successfully"}