from fastapi import APIRouter, Depends, status, Request
from src.core.users import controller
from src.core.auth import controller as ct
from src.models.models import CreateSpaceModel
from src.core.users.dtos import SpaceResponseSchema, ImagesResponseSchema
from typing import List
# adding a route inside a fastapi routes

# /127:800/user/{your route name}
user_router = APIRouter(prefix="/users", tags=["Spaces"])

@user_router.post("/create-space", status_code=status.HTTP_201_CREATED, response_model=SpaceResponseSchema)
def create_space(request : Request,space_model : CreateSpaceModel,current_user= Depends(ct.is_authenticated)):
    return controller.create_space(space_model, current_user.id, request.app.state.db)


@user_router.get("/get-spaces", status_code=status.HTTP_200_OK, response_model=List[SpaceResponseSchema])
def get_spaces(request : Request,current_user= Depends(ct.is_authenticated)):
    return controller.get_spaces(current_user.id, request.app.state.db)


@user_router.post("/join-space", status_code=status.HTTP_200_OK, response_model= SpaceResponseSchema)
def join_space(request : Request,space_model : CreateSpaceModel, current_user= Depends(ct.is_authenticated)):
    return controller.join_space(space_model, request.app.state.db,current_user.id)

@user_router.get("/get-images",status_code=status.HTTP_200_OK,response_model=List[ImagesResponseSchema])
def get_images( request: Request, space_id: str,current_user= Depends(ct.is_authenticated)):
    return controller.get_images(current_user.id, request.app.state.db, space_id, request.app.state.storage_bucket)