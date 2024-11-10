from fastapi import APIRouter
from database.database import get_db
from models.models import User
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from auth.auth import check_login

router = APIRouter()

@router.post("/login/")
async def login_user(email: str, password: str, db: Session = Depends(get_db)):
    try:
        if check_login(db, email, password):
            return {"message": "Login successful"}
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")