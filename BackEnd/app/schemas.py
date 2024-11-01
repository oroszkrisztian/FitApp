from pydantic import BaseModel
from decimal import Decimal
from typing import List, Optional
from datetime import datetime

class FoodBase(BaseModel):
    name: str
    calories: Decimal
    protein: Decimal
    fat: Decimal
    carbs: Decimal

class Food(FoodBase):
    food_id: int

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
