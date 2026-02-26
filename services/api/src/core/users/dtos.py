

from datetime import datetime
from pydantic import BaseModel
from typing import Optional, Any
class SpaceResponseSchema(BaseModel):
    id: str
    name: str    
    created_at: Any= None
    updated_at: Optional[datetime] = None


class ImagesResponseSchema(BaseModel):
    id: str
    file_name: str    
    uploaded_at: Optional[datetime] = None
    url : str