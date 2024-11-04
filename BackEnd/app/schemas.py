from pydantic import BaseModel
from decimal import Decimal
from typing import List, Optional
from datetime import datetime

# Input schema (without food_id) for creation requests
class FoodCreate(BaseModel):
    name: str
    calories: Decimal
    protein: Decimal
    fat: Decimal
    carbs: Decimal

# Output schema (with food_id) for responses
class FoodResponse(FoodCreate):
    food_id: int  # Includes `food_id` only in the response

    class Config:
        orm_mode = True

class UserProfileBase(BaseModel):
    height: Decimal
    weight: Decimal
    age: int
    gender: str
    username: str

class UserProfile(UserProfileBase):
    profile_id: int
    user_id: int

    class Config:
        orm_mode = True

class UserFoodBase(BaseModel):
    user_id: int
    food_id: int
    grams: Decimal
    consumed_at: datetime

class UserFood(UserFoodBase):
    log_id: int

    class Config:
        orm_mode = True
