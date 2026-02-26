from fastapi import FastAPI
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from insightface.app import FaceAnalysis
import logging
import uvicorn
from src_face_service.route.router import face_router
from qdrant_client import QdrantClient
from firebase_admin import  storage, credentials
from src_face_service.db.db import get_db
import os
import firebase_admin
load_dotenv()
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logging = logging.getLogger(__name__)
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        logging.info("Starting up the application...")
        face_app = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
        face_app.prepare(ctx_id=0, det_size=(640,640))

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
        app.state.db = get_db()
        app.state.storage_bucket = storage.bucket()

        app.state.face_app = face_app
        app.state.qdrant_client = QdrantClient(url=os.getenv("QDRANT_HOST"), api_key=os.getenv("QDRANT_API_KEY"))
        logging.info("Application startup complete.")
    except Exception as e:
        logging.error(f"Error during application startup: {e}")
        raise
    yield
    logging.info("Shutting down the application...")
    pass


app = FastAPI(lifespan=lifespan)

app.include_router(face_router)


if __name__ == "__main__":
    uvicorn.run(app,port=8001)