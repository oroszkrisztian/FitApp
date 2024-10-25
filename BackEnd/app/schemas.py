from pydantic import BaseModel
from decimal import Decimal
from typing import List, Optional

class FoodBase(BaseModel):
    name: str
    calories: Decimal
    protein: Decimal
    fat: Decimal
    carbs: Decimal

class Food(FoodBase):
    food_id: int

    class Config:
        orm_mode = True  # Lehetővé teszi az SQLAlchemy modellek közvetlen használatát

class UserFoodBase(BaseModel):
    user_id: int
    food_id: int
    grams: Decimal
    eaten_at: str  # Dátum szövegként

class UserFood(UserFoodBase):
    user_food_id: int

    class Config:
        orm_mode = True
