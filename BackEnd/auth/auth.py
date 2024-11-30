import bcrypt
from sqlalchemy.orm import Session
from models.models import User, UserProfile

def create_user(db: Session, email: str, password: str, height: float, weight: float, age: int, gender: str, username: str, activity: int):
    # Hash the password
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    # Create user and profile objects
    user = User(email=email, password=hashed_password.decode('utf-8'))
    db.add(user)
    db.commit()
    db.refresh(user)

    profile = UserProfile(user_id=user.user_id, height=height, weight=weight, age=age, gender=gender, username=username, activity=activity)
    db.add(profile)
    db.commit()

    return user

def check_login(db: Session, email: str, password: str):
    # Query user by email
    user = db.query(User).filter(User.email == email).first()
    if user:
        # Compare password with hashed password
        if bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            return True
        else:
            return False
    else:
        return False