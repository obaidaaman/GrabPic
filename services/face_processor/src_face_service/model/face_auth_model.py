from pydantic import BaseModel
from fastapi import UploadFile, File

class FaceAuthRequest(BaseModel):
    image: UploadFile = File(...)
    
    