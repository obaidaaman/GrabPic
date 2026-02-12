from fastapi import FastAPI
import uvicorn
from src.core.users.router import user_router     
from src.core.auth.router import auth_router     

app = FastAPI()

app.include_router(user_router)
app.include_router(auth_router)




 
if __name__ == "__main__":
    uvicorn.run(app)