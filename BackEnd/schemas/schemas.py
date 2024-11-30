from pydantic import BaseModel
from decimal import Decimal
from typing import List, Optional   
from datetime import date

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
    consumed_at: date

class UserFood(UserFoodBase):
    log_id: int

    class Config:
        orm_mode = True

class UserResponse(BaseModel):
    email: str
    password: str

    class Config:
        orm_mode = True

class UserProfileResponse(BaseModel):
    user_id: int
    height: float
    weight: float
    age: int
    gender: str
    username: str
    user: UserResponse
    activity: int

    class Config:
        orm_mode = True

class FoodDetails(BaseModel):
    food_id: int
    name: str
    calories: float
    protein: float
    fat: float
    carbs: float

    class Config:
        orm_mode = True

# Schema for user food log including food details
class UserFoodLogResponse(BaseModel):
    log_id: int
    user_id: int
    grams: float
    consumed_at: date
    food: FoodDetails  # Nested schema for food details

    class Config:
        orm_mode = True

class UserRecommendedResponse(BaseModel):
    user_id: int
    calorie: float
    protein: float
    fat: float
    carbs: float

    class Config:
        orm_mode = True
