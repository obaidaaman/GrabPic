from src.models.models import AuthModel, LoginModel
from firebase_admin import firestore
from datetime import datetime, timezone
from fastapi import HTTPException, status, Request, Depends
from src.utils.db import get_db
from pwdlib import PasswordHash
from dotenv import load_dotenv
import jwt
import os
load_dotenv()

password_hash = PasswordHash.recommended()

def get_password_hash(password:str) -> str:
    return password_hash.hash(password)


def verify_password(plain_password, hashed_password):
    return password_hash.verify(plain_password, hashed_password)



def create_auth(auth:AuthModel, db : firestore.client):
    # Username validation
    # email validation
    # Then continue to create the user in the database



    user_collection = db.collection("users")

    existing_user = (
        user_collection.where("username", "==", auth.username)
        .limit(1)
        .stream()
    )
    existing_email = (
        user_collection.where("email", "==", auth.email)
        .limit(1)
        .stream())
    if any(existing_user) or any(existing_email):
        raise HTTPException(400, detail="Username or emailalready exists")
    
    doc_ref = user_collection.document()
    hashed_password = get_password_hash(auth.password)
    doc_ref.set({
        "username" : auth.username,
        "password" : hashed_password,
        "email" : auth.email,
        "created_at": datetime.now(timezone.utc),
        "is_active" : True
    })
    return {
        "id": doc_ref.id,
        "username": auth.username,
        "email": auth.email
    }



def login_user(login_model : LoginModel, db : firestore.client):
    user_collection = db.collection("users")
    existing_user = (
        user_collection.where("username", "==", login_model.username)
        .limit(1)
        .stream()
    )
    user_docs = list(existing_user)
    if not user_docs:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Username is wrong")
    user_doc = user_docs[0]
    user_data = user_doc.to_dict()
    if not verify_password(login_model.password, user_data["password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Password is incorrect")
    
    # payload {} --> data on which token should be created
    # exp --> we can also add expiry time for this token, currently not required.
    token = jwt.encode({"_id": user_doc.id},os.getenv("SECRET_KEY"), os.getenv("ALGORITHM"))
    return {
        "message" : "Login Success",
        "token" : token
    }

def is_authenticated(request : Request, db = Depends(get_db)):
    token = request.headers.get("authorization")
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authorization header missing")
    token = token.split(" ")[-1]
    data = jwt.decode(token,os.getenv("SECRET_KEY"),algorithms=[ os.getenv("ALGORITHM")])
    if not data:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    id = data.get("_id")
    user = db.collection("users").document(id).get()
    if user.exists:
        user_data =user.to_dict()
        return {
            "id": user.id,
            "username": user_data.get("username"),
            "email": user_data.get("email"),
        }

    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") 
