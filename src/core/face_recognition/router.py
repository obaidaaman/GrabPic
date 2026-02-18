from fastapi import FastAPI, APIRouter, UploadFile, File, status
from typing import List
from .controller import upload_photos
file_router = APIRouter(prefix="/files", tags=["Files"])

@file_router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_files(files : List[UploadFile]= File(...)):
    list_all_results = []
    if not files:
        return {"List": []}
    
    for file in files:
        content = await file.read()
        # embeddings = get_faces(content)
        # embeddingsList.append(embeddings)
        listembedding =  await upload_photos(content, file.filename)
        list_all_results.extend(listembedding)
    
    return {"List" : list_all_results}


