from src.core.auth.dtos import AuthResponseModel
from firebase_admin import firestore
from datetime import datetime, timezone, timedelta
from fastapi import HTTPException, status, Request
from pwdlib import PasswordHash
from dotenv import load_dotenv
import os, logging, jwt, uuid
from qdrant_client.models import  PointStruct, VectorParams, Distance

load_dotenv()

logger = logging.getLogger(__name__)

_SECRET_KEY = os.getenv("SECRET_KEY")
_ALGORITHM  = os.getenv("ALGORITHM", "HS256")
 
if not _SECRET_KEY:
    raise RuntimeError("SECRET_KEY environment variable is not set. Cannot start server.")
 

_KNOWN_INSECURE_KEYS = {
    "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7",
    "secret",
    "your-secret-key",
}
if _SECRET_KEY in _KNOWN_INSECURE_KEYS:
    raise RuntimeError(
        "SECRET_KEY is set to a well-known insecure value. "
        "Generate a new one with: python -c \"import secrets; print(secrets.token_hex(32))\""
    )
 
if _ALGORITHM not in ("HS256", "HS384", "HS512"):
    raise RuntimeError(f"Unsupported ALGORITHM '{_ALGORITHM}'. Use HS256, HS384, or HS512.")

 
def _create_token(user_id: str, is_organiser: bool) -> str:
    
    now = datetime.now(timezone.utc)
    payload = {
        "_id":          user_id,
        "is_organiser": is_organiser,   # FIX: role is set server-side, not by the caller
        "iat":          now,            # FIX: missing in original
        "exp":          now + timedelta(days=7),
    }
    return jwt.encode(payload, _SECRET_KEY, algorithm=_ALGORITHM)
 
 
def _decode_token(raw_token: str) -> dict:

    try:
        return jwt.decode(raw_token, _SECRET_KEY, algorithms=[_ALGORITHM])
 
    except jwt.ExpiredSignatureError:
       
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please re-authenticate.",
        )
 
    except jwt.InvalidSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token signature is invalid.",
        )
 
    except jwt.DecodeError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is malformed.",
        )
 
    except jwt.InvalidAlgorithmError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token algorithm mismatch.",
        )
 
    except jwt.PyJWTError as e:
        # Catch-all for any other JWT error — still specific enough to log
        logger.warning("JWT validation failed: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token.",
        )
# password_hash = PasswordHash.recommended()

# def get_password_hash(password:str) -> str:
#     return password_hash.hash(password)


# def verify_password(plain_password, hashed_password):
#     return password_hash.verify(plain_password, hashed_password)






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
                 logger.info("Face matched — existing user logging in: %s", user_id)
                 user_doc = db.collection("users").document(user_id).get()
                 if user_doc.exists:
                    isOrganiser = user_doc.to_dict().get("isOrganiser", False) 
                 
    else:
                 is_new_user = True
                 user_id = str(uuid.uuid4())
                 
                 client.upsert(collection_name="faces_collection",wait=True,points=[
                      
                 PointStruct(id=user_id,vector=new_emb,payload={"created_at": str(datetime.now())
                     }
                     )
             ]
              )
                 db.collection("users").document(user_id).set({
                 "face_id": user_id,
                 "auth_type": "face_biometric",
                 "isOrganiser" : isOrganiser,
                "first_seen": datetime.now(timezone.utc),
                
            })
                 logger.info("New user created: ", user_id, isOrganiser)
    
    token = _create_token(user_id,isOrganiser)
    return AuthResponseModel(
          id=user_id,
          token=token,
          message="Login successful" if not is_new_user else "Account created and logged in",
            is_new_user=is_new_user
    )
    
def is_authenticated(request: Request) -> AuthResponseModel:
    
    auth_header = request.headers.get("authorization")
    if not auth_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header.",
        )
 
   
    parts = auth_header.split(" ")
    if len(parts) != 2 or parts[0].lower() != "bearer":
        
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header must be in the format: Bearer <token>",
        )
 
    raw_token = parts[1]
    data = _decode_token(raw_token)   
 
    user_id = data.get("_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload is missing user ID.",
        )
 
    db = request.app.state.db
    user_doc = db.collection("users").document(user_id).get()
 
    if not user_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found.",
        )
 
    user_data = user_doc.to_dict()
 
    return AuthResponseModel(
        id=user_doc.id,
        username=user_data.get("username", ""),
        email=user_data.get("email", ""),
        is_profile_complete="username" in user_data and "email" in user_data,
        message="Authenticated",
        
        is_new_user="username" not in user_data,
    )