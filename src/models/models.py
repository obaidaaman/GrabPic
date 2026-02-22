from pydantic import BaseModel, Field
from typing import Optional
class AuthModel(BaseModel):
    username: str= Field(..., description="john_doe")
    password: str = Field(..., description="password123")
    email : str =Field(..., description="Email address of the user")

class CreateSpaceModel(BaseModel):
    
    space_name : str = Field(..., description="Name of the space to be created")
    space_password : str = Field(..., description="Password of the space")
    created_by : Optional[str] = Field(..., description="User who created the space")
    space_id : Optional[str] = None
    

class LoginModel(BaseModel):
    username: str = Field(..., description="john_doe")
    password: str = Field(..., description="password123")


class UploadRequestModel(BaseModel):
    fileName: list[str] = Field(..., description="Name of the file being uploaded")
    space_id: str = Field(..., description="ID of the space where the photo is being uploaded")