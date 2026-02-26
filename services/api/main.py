from fastapi import FastAPI
from contextlib import asynccontextmanager
import firebase_admin
import uvicorn
import logging
from src.core.users.router import user_router     
from src.core.auth.router import auth_router     
from src.core.face_recognition.router import file_router    
from firebase_admin import storage, credentials
from qdrant_client import QdrantClient
import os
from dotenv import load_dotenv
from src.utils.db import get_db
import httpx
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)
@asynccontextmanager
async def lifespan(app : FastAPI):
    logger.info("Starting up the server")
    try:
        
        # cred = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        # if not cred:
        #     raise ValueError("GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.")
        cred_dict= {
           "type": os.getenv("FirebaseType"),
           "project_id": os.getenv("project_id"),
           "private_key_id": os.getenv("private_key_id"),
           "private_key": os.getenv("private_key"),
           "client_email": os.getenv("client_email"),
           "client_id": os.getenv("client_id"),
           "auth_uri": os.getenv("auth_uri"),
           "token_uri": os.getenv("token_uri"),
           "auth_provider_x509_cert_url": os.getenv("auth_provider_x509_cert_url"),
           "client_x509_cert_url": os.getenv("client_x509_cert_url"),
           "universe_domain": os.getenv("universe_domain")
       }
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred, {
        'storageBucket': os.getenv("STORAGE_BUCKET_NAME") 
    })
        app.state.qdrant_client = QdrantClient(url=os.getenv("QDRANT_HOST"), api_key=os.getenv("QDRANT_API_KEY"))
        
        app.state.db = get_db()
        app.state.storage_bucket = storage.bucket()
        app.state.http_client = httpx.AsyncClient()
       
        logger.info("AI Models (buffalo_l) loaded successfully into memory.")
    except Exception as e:
        logger.error(f"Failed to load AI models:{str(e)}")
        raise
    yield
    logger.info("Shutting down: Releasing resources...")

app = FastAPI(lifespan=lifespan)

app.include_router(user_router)
app.include_router(auth_router)
app.include_router(file_router)




 
if __name__ == "__main__":
    uvicorn.run(app)