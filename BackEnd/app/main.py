from fastapi import FastAPI
from app.routes import router
from app.database import engine
from app.models import Base

app = FastAPI()

# Create all tables in the database
Base.metadata.create_all(bind=engine)

# Include the API routes
app.include_router(router)
