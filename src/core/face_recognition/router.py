from fastapi import  APIRouter,status, Request, BackgroundTasks
from typing import List
from .controller import  get_signed_urls, run_bulk_ai_processing
from src.models.models import UploadRequestModel

file_router = APIRouter(prefix="/files", tags=["Files"])

@file_router.post("/get-presigned-url", status_code=status.HTTP_200_OK)
async def get_presigned_url(request: Request, data : UploadRequestModel):
    bucket = request.app.state.storage_bucket
    return  await get_signed_urls(data.fileName, data.space_id, bucket)
    

    

@file_router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_files(requests: Request, storage_paths: List[str], space_id: str, background_tasks : BackgroundTasks):

    

    background_tasks.add_task(
        run_bulk_ai_processing,
        paths=storage_paths,
        space_id=space_id,
        face_app=requests.app.state.face_engine,
        qdrant=requests.app.state.qdrant_client,
        db=requests.app.state.db,
        bucket=requests.app.state.storage_bucket
    )
   

    return {
        "status": "Accepted",
        "message": f"Processing {len(storage_paths)} images in the background.",
        "space_id": space_id
    }


