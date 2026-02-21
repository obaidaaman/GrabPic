from pydantic import BaseModel

class AuthResponseModel(BaseModel):
    id: str
    token: str
    message: str
    is_new_user: bool