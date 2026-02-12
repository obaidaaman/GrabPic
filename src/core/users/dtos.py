

import datetime
from pydantic import BaseModel

class SpaceResponseSchema(BaseModel):
    id: int
    name: str
    description: str
    created_at: datetime
    updated_at: datetime