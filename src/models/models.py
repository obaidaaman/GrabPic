from pydantic import BaseModel, Field

class AuthModel(BaseModel):
    username: str= Field(..., description="john_doe")
    password: str = Field(..., description="password123")
    email : str =Field(..., description="Email address of the user")

class CreateSpaceModel(BaseModel):
    
    space_name : str = Field(..., description="Name of the space to be created")
    created_by : str = Field(..., description="User who created the space")

class LoginModel(BaseModel):
    username: str = Field(..., description="john_doe")
    password: str = Field(..., description="password123")