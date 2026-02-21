

from datetime import datetime
from pydantic import BaseModel
from typing import Optional
class SpaceResponseSchema(BaseModel):
    id: int
    name: str    
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ImagesResponseSchema(BaseModel):
    id: int
    file_name: str    
    uploaded_at: Optional[datetime] = None
    url : str