from pydantic import BaseModel

class AuthCreatedSchema(BaseModel):
    username: str
    password: str