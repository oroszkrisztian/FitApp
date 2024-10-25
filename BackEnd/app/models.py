from sqlalchemy import Column, Integer, String, ForeignKey, DECIMAL, Enum
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)

    profile = relationship("UserProfile", back_populates="user", uselist=False)
    # Kapcsolat a UserFood táblával
    foods = relationship("UserFood", back_populates="user")

class UserProfile(Base):
    __tablename__ = "user_profiles"

    profile_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    height = Column(DECIMAL(5, 2))
    weight = Column(DECIMAL(5, 2))
    age = Column(Integer)
    gender = Column(Enum("male", "female", "other", name="gender"))

    user = relationship("User", back_populates="profile")

class Food(Base):
    __tablename__ = "foods"

    food_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    calories = Column(DECIMAL(5, 2))
    protein = Column(DECIMAL(5, 2))
    fat = Column(DECIMAL(5, 2))
    carbs = Column(DECIMAL(5, 2))

    # Kapcsolat a UserFood táblával
    user_foods = relationship("UserFood", back_populates="food")

class UserFood(Base):
    __tablename__ = "user_foods"

    user_food_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    food_id = Column(Integer, ForeignKey("foods.food_id"))
    grams = Column(DECIMAL(5, 2))
    eaten_at = Column(String)  # A dátumot itt szövegként tároljuk, de célszerű DATETIME típusra is alakítani.

    # Kapcsolat a User és Food táblákkal
    user = relationship("User", back_populates="foods")
    food = relationship("Food", back_populates="user_foods")
