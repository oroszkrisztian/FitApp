from fastapi import FastAPI
from routes import delete_food_by_id, delete_user_by_id, foods, login,post_food, register, user_foods_by_id, users, user_post_food, update_user_info, get_user_info  # Import route modules

app = FastAPI()

app.include_router(users.router)
app.include_router(foods.router)
app.include_router(user_foods_by_id.router)
app.include_router(user_post_food.router)
app.include_router(delete_user_by_id.router)
app.include_router(delete_food_by_id.router)
app.include_router(login.router)
app.include_router(register.router)
app.include_router(post_food.router)
app.include_router(update_user_info.router)
app.include_router(get_user_info.router)