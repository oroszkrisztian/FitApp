from sqlalchemy import Column, Integer, String, ForeignKey, DECIMAL, Enum
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)

    profile = relationship("UserProfile", back_populates="user", uselist=False)

class UserProfile(Base):
    __tablename__ = "user_profiles"

    profile_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    height = Column(DECIMAL(5, 2))
    weight = Column(DECIMAL(5, 2))
    age = Column(Integer)
    gender = Column(Enum("male", "female", "other", name="gender"))

    user = relationship("User", back_populates="profile")