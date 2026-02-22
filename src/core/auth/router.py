from fastapi import APIRouter, status, Request, File, UploadFile
from src.core.auth import controller

from src.core.auth.dtos import AuthResponseModel

auth_router = APIRouter(prefix="/auth", tags=["Auth"])


@auth_router.post("/face-auth",status_code=status.HTTP_200_OK, response_model=AuthResponseModel)
def face_auth(is_organiser: bool,requests: Request,file : UploadFile = File(...)):
    contents = file.file.read()
    

    return controller.face_auth_portal(is_organiser, contents, requests.app.state.db, requests.app.state.face_engine, requests.app.state.qdrant_client)