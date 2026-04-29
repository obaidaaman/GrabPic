import asyncio

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
from qdrant_client.models import VectorParams, Distance
import os
from dotenv import load_dotenv
from src.utils.db import get_db
import httpx
import time
from upstash_redis.asyncio import Redis
from src.core.rabbitmq.sender import create_rabbitmq_connection, declare_queues
from fastapi.middleware.cors import CORSMiddleware
import aio_pika
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
        cred_dict["private_key"] = cred_dict["private_key"].replace("\\n", "\n")
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred, {
        'storageBucket': os.getenv("STORAGE_BUCKET_NAME") 
    })
        qdrant_client = QdrantClient(url=os.getenv("QDRANT_HOST"), api_key=os.getenv("QDRANT_API_KEY"))
        if not qdrant_client.collection_exists("faces_collection"):
            qdrant_client.create_collection(
                collection_name="faces_collection"
         , vectors_config=VectorParams(size=512,distance= Distance.COSINE))
        app.state.qdrant_client = qdrant_client
        
        app.state.db = get_db()
        # connection = RabbitMQConnection()
        # publisher = RabbitMQPublisher(connection)
        # app.state.rabbitmq = publisher
        rabbitmq_connection = await create_rabbitmq_connection()
        async with rabbitmq_connection.channel() as ch:
            await declare_queues(ch)
        app.state.rabbitmq = rabbitmq_connection
        app.state.storage_bucket = storage.bucket()
        app.state.http_client = httpx.AsyncClient()
        rabbitmq = await aio_pika.connect_robust(os.getenv("RABBIT_URI"))
        app.state.rabbitmq = rabbitmq
        app.state.redis_conn = Redis(url=os.getenv("UPSTASH_REDIS_URL"), token=os.getenv("UPSTASH_REDIS_TOKEN"))
        
        try:
            qdrant_client.create_payload_index(
            collection_name="faces_collection",
            field_name="space_id",
            field_schema={"type": "keyword"}
        )
        except Exception:
            pass
        
    except Exception as e:
        logger.error(f"Failed to load AI models:{str(e)}")
        raise
    yield
    await app.state.rabbitmq.close()
    logger.info("Shutting down: Releasing resources...")
    
origins = [
    "*"
]
app = FastAPI(lifespan=lifespan, debug=True)

app.include_router(user_router)
app.include_router(auth_router)
app.include_router(file_router)
app.add_middleware(CORSMiddleware,
    allow_origins= origins,
    allow_methods=["*"],     # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],)


# @app.get("/health")
# def healthy():
#     print("Received health check request.")
#     time.sleep(3)
#     print("API is healthy and running!")

# @app.get("/health-async")

if __name__ == "__main__":
    uvicorn.run(app)