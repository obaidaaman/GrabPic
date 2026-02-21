from fastapi import FastAPI
from contextlib import asynccontextmanager
import firebase_admin
import uvicorn
import logging
from src.core.users.router import user_router     
from src.core.auth.router import auth_router     
from src.core.face_recognition.router import file_router    
from firebase_admin import firestore, storage, credentials
from insightface.app import FaceAnalysis
from qdrant_client import QdrantClient
import os
from dotenv import load_dotenv
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
        face_app = FaceAnalysis(name="buffalo_l",providers=['CPUExecutionProvider'])
        
        face_app.prepare(ctx_id=0,det_size=(640,640))
       
        cred = credentials.Certificate(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
        firebase_admin.initialize_app(cred, {
        'storageBucket': os.getenv("STORAGE_BUCKET_NAME") 
    })
        app.state.qdrant_client = QdrantClient(url="http://localhost:6333")
        app.state.face_engine= face_app
        app.state.db = firestore.client()
        app.state.storage_bucket = storage.bucket()
       
       
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