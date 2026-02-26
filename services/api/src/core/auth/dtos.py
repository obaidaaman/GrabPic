from pydantic import BaseModel

class AuthResponseModel(BaseModel):
    id: str
    token: str = None
    message: str
    is_new_user: bool = False
    username:str = None
    email:str = None
    is_profile_complete: bool = False