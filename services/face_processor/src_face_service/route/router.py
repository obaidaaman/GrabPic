from fastapi import APIRouter, Request, status, BackgroundTasks, Body
from ..controller.face_auth import process_embedding
from src_face_service.controller.controller import run_bulk_ai_processing
from typing import List
from pydantic import BaseModel
class FaceUploadRequest(BaseModel):
    storage_paths: List[str]
    space_id: str
face_router = APIRouter(prefix="/face", tags=["face"])

@face_router.post("/embedding", status_code=status.HTTP_201_CREATED)
def process_embedding_route(request: Request,content: bytes = Body(...)):
    
    return process_embedding(content,request.app.state.face_app)



@face_router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_files(requests: Request, background_tasks : BackgroundTasks, face_upload_request: FaceUploadRequest):

    

    await run_bulk_ai_processing(
        paths=face_upload_request.storage_paths,
        space_id=face_upload_request.space_id,  
        face_app=requests.app.state.face_app,
        qdrant=requests.app.state.qdrant_client,
        db=requests.app.state.db,
        bucket=requests.app.state.storage_bucket
    )
   

    return {
        "status": "Accepted",
        "message": f"Processing {len(face_upload_request.storage_paths)} images in the background.",
        "space_id": face_upload_request.space_id
    }
