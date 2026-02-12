from fastapi import APIRouter, Depends, status
from src.core.users import controller
from src.core.auth import controller as ct
from src.models.models import CreateSpaceModel
from src.utils.db import get_db
# adding a route inside a fastapi routes

# /127:800/user/{your route name}
user_router = APIRouter(prefix="/users")

@user_router.post("/create-space", status_code=status.HTTP_201_CREATED)
def create_space(space_model : CreateSpaceModel,current_user= Depends(ct.is_authenticated), db = Depends(get_db)):
    return controller.create_space(space_model, current_user["id"], db)


@user_router.get("/get-spaces", status_code=status.HTTP_200_OK)
def get_spaces(current_user= Depends(ct.is_authenticated), db = Depends(get_db)):
    return controller.get_spaces(current_user["id"], db)

