from fastapi import APIRouter, status, Request, File, UploadFile
from src.core.auth import controller

from src.core.auth.dtos import AuthResponseModel

auth_router = APIRouter(prefix="/auth", tags=["Auth"])


@auth_router.post("/face-auth",status_code=status.HTTP_200_OK, response_model=AuthResponseModel)
async def face_auth(is_organiser: bool,requests: Request,file : UploadFile = File(...)):
    contents = file.file.read()
    

    return await controller.face_auth_portal(is_organiser, contents, requests.app.state.db, requests.app.state.qdrant_client, requests.app.state.http_client)




@auth_router.post("/upload", status_code=status.HTTP_201_CREATED)
async def test_embedding(file: UploadFile = File(...)):
    contents = file.file.read()
    return  await controller.face_auth_micro_service(contents)

