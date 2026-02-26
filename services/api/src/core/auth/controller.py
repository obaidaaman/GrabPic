from src.core.auth.dtos import AuthResponseModel
from firebase_admin import firestore
from datetime import datetime, timezone, timedelta
from fastapi import HTTPException, status, Request
from pwdlib import PasswordHash
from dotenv import load_dotenv
import jwt
import os
from qdrant_client.models import  PointStruct, VectorParams, Distance
import uuid
load_dotenv()

password_hash = PasswordHash.recommended()

def get_password_hash(password:str) -> str:
    return password_hash.hash(password)


def verify_password(plain_password, hashed_password):
    return password_hash.verify(plain_password, hashed_password)




# Chckeing if the face embedding exists in the DB or not, if yes then fetch that uid only or else create new vector and get that id.

# User clicks "Create Space"
# Frontend checks for a local JWT. None? Show Camera Modal
# User takes a selfie --> sent to face_auth_portal
# Backend returns JWT. Frontend saves it and then proceeds to the "Create Space" form

async def face_auth_portal(isOrganiser: bool,contents: bytes, db : firestore.client, client, httpx_client):

    # nparr = np.frombuffer(contents, np.uint8)
    # img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
      
    response =  await httpx_client.post(os.getenv("MODEL_MICRO_SERVICE_URL"), content=contents,headers={"Content-Type": "application/octet-stream"})
    data = response.json()
    if not data.get("embedding"):
         return { "status" : "No faces detected"}

    # face = faces[0]
    if not client.collection_exists("faces_collection"):
         client.create_collection(
        collection_name="faces_collection",
        vectors_config=VectorParams(size=512, distance=Distance.COSINE),
    )
    new_emb = data["embedding"]
    search_results = client.query_points(
            collection_name="faces_collection",
            query=new_emb,
            limit=1,
            score_threshold=0.65  
        )
    
    user_id = None
    is_new_user = False
    if search_results.points:
                 
                 user_id = search_results.points[0].id
                 print("User already exists, logging in")
                 
    else:
                 is_new_user = True
                 user_id = str(uuid.uuid4())
                 
                 client.upsert(collection_name="faces_collection",wait=True,points=[
                 PointStruct(id=user_id,vector=new_emb,payload={"created_at": str(datetime.now()) })])
                 db.collection("users").document(user_id).set({
                 "face_id": user_id,
                 "auth_type": "face_biometric",
                 "isOrganiser" : isOrganiser,
                "first_seen": datetime.now(timezone.utc),
                
            })
                 print("Signup created")
    
    token_data = {
         "_id" : user_id,
         "exp" : datetime.now(timezone.utc) + timedelta(days=7)
    }
    token = jwt.encode(token_data, os.getenv("SECRET_KEY"), os.getenv("ALGORITHM"))
    return AuthResponseModel(
          id=user_id,
          token=token,
          message="Login successful" if not is_new_user else "Account created and logged in",
            is_new_user=is_new_user
    )
    
def is_authenticated(request: Request):
    token = request.headers.get("authorization")
    db = request.app.state.db
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    
    try:
        token = token.split(" ")[-1]
        data = jwt.decode(token, os.getenv("SECRET_KEY"), algorithms=[os.getenv("ALGORITHM")])
        user_id = data.get("_id")
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

   
    user_doc = db.collection("users").document(user_id).get()
    
    if not user_doc.exists:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    user_data = user_doc.to_dict()
    
    
    return AuthResponseModel(
        id=user_doc.id,
        username=user_data.get("username", ""),
        email=user_data.get("email", ""),
        is_profile_complete="username" in user_data and "email" in user_data,
        
        message="Authenticated",
        is_new_user= user_doc.id not in user_data,  #
    )

