from fastapi import  APIRouter,status, Request, Depends
from typing import List
from .controller import  get_signed_urls,call_face_embedding_service
from src.models.models import UploadRequestModel, FaceEmbeddingRequestModel
from src.core.users.controller import verify_space_acess
from src.core.auth.controller import is_authenticated

file_router = APIRouter(prefix="/files", tags=["Files"])

@file_router.post("/url", status_code=status.HTTP_200_OK)
async def get_presigned_url(request: Request, data : UploadRequestModel, current_user = Depends(is_authenticated)):
    bucket = request.app.state.storage_bucket

    db = request.app.state.db
    verify_space_acess(data.space_id,current_user.id,db)
    return  await get_signed_urls(data.fileName, data.space_id, bucket)
    

    

@file_router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_files(requests: Request, data: FaceEmbeddingRequestModel, current_user = Depends(is_authenticated)):

    

    await call_face_embedding_service(
        data.storagePaths,
        data.space_id,
        data.email,
        requests.app.state.rabbitmq)
   

    return {
        "status": "Accepted",
        "message": f"Processing {len(data.storagePaths)} images in the background.",
        "space_id": data.space_id
    }


@file_router.get("/status", status_code=status.HTTP_200_OK)
async def job_status(request: Request, job_id : str, current_user = Depends(is_authenticated)):
    """
    Returns the status of the Background Job performed 
    Args: 
    job_id : id of the job being performed
    request : Request parameter to authenticate user 
    """
    status = await request.app.state.redis_conn.get(f"job_status:{job_id}")
    return {
        "job_id" : job_id,
        "status" : status or "not found"
    }   