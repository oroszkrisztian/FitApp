from sqlalchemy import Column, Integer, String, ForeignKey, DECIMAL, Enum, Date, Float
from sqlalchemy.orm import relationship
from database.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "Users"  

    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)

    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    foods = relationship("UserFoodLog", back_populates="user", cascade="all, delete-orphan")
    recommended = relationship("UserRecommended", back_populates="user", cascade="all, delete-orphan")

class UserProfile(Base):
    __tablename__ = "User_profiles"  

    profile_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("Users.user_id"))  
    height = Column(DECIMAL(5, 2))
    weight = Column(DECIMAL(5, 2))
    age = Column(Integer)
    gender = Column(Enum("male", "female", "other", name="gender"))
    username = Column(String(50), nullable=False)
    activity = Column(Integer, nullable=False)

    user = relationship("User", back_populates="profile")

class Food(Base):
    __tablename__ = "Foods" 

    food_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    calories = Column(DECIMAL(7, 2))
    protein = Column(DECIMAL(5, 2))
    fat = Column(DECIMAL(5, 2))
    carbs = Column(DECIMAL(5, 2))

    user_foods = relationship("UserFoodLog", back_populates="food") 

class UserFoodLog(Base):
    __tablename__ = "User_food_logs"

    log_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("Users.user_id"))
    food_id = Column(Integer, ForeignKey("Foods.food_id"))
    grams = Column(DECIMAL(5, 2))
    consumed_at = Column(Date, default=datetime.today)

    user = relationship("User", back_populates="foods")
    food = relationship("Food", back_populates="user_foods")

class UserRecommended(Base):
    __tablename__ = "User_recommended"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("Users.user_id"), nullable=False)
    calorie = Column(Float, nullable=False)
    protein = Column(Float, nullable=False)
    fat = Column(Float, nullable=False)
    carbs = Column(Float, nullable=False)

    user = relationship("User", back_populates="recommended")
