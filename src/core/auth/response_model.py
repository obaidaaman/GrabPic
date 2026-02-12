from pydantic import BaseModel


class AuthResponseModel(BaseModel):
    id: str
    username: str
    email: str
    