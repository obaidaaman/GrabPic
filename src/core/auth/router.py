from fastapi import APIRouter, Depends, status, Request
from src.core.auth import controller
from src.models.models import AuthModel, LoginModel
from src.utils.db import get_db
from src.core.auth.response_model import AuthResponseModel
from firebase_admin import firestore
auth_router = APIRouter(prefix="/auth")

# adding a route inside a fastapi routes
# now auth_router will have /auth as prefix for all the routes inside it, which is now connected to main.py

@auth_router.post("/create-auth", response_model= AuthResponseModel,  status_code=status.HTTP_201_CREATED)
def create_auth(auth : AuthModel, db : firestore.client = Depends(get_db)):
    return controller.create_auth(auth, db)

@auth_router.post("/login-user", status_code= status.HTTP_200_OK)
def login(login_model : LoginModel, db: firestore.client = Depends(get_db)):
    return controller.login_user(login_model, db)


@auth_router.get("/is-authenticated", status_code=status.HTTP_200_OK, response_model=AuthResponseModel)
def is_auth(request: Request, db:firestore.client = Depends(get_db)):
    return controller.is_authenticated(request,db)

