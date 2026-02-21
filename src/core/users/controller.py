from src.models.models import CreateSpaceModel
from google.cloud import firestore
from fastapi import HTTPException, status
from pwdlib import PasswordHash
from dotenv import load_dotenv
from src.core.users.dtos import SpaceResponseSchema, ImagesResponseSchema


load_dotenv()

password_hash = PasswordHash.recommended()


def get_password_hash(password: str):
    return password_hash.hash(password)


def verify_password(plain_password : str, hashed_password: str):
    return password_hash.verify(plain_password,hashed_password)



def create_space(create_space_model: CreateSpaceModel, user_id, db):
    try:
        user_doc = db.collection("users").document(user_id).get()

        if not user_doc.exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        space_doc = db.collection("spaces").document()
        hashed_password = get_password_hash(create_space_model.space_password)
        space_doc.set({
            "user_doc_id": user_id,
            "space_name": create_space_model.space_name,
            "space_password" : hashed_password,
            "created_by": create_space_model.created_by,
            "created_at": firestore.SERVER_TIMESTAMP
        })

        return SpaceResponseSchema(id=space_doc.id, name=create_space_model.space_name, created_at=firestore.SERVER_TIMESTAMP)

    except Exception as e:
        return {"status": "Error", "message": str(e)}

def get_spaces(user_doc_id, db):
    try:
        spaces = []
        
        collection = db.collection("membership")
        docs = collection.where("user_id", "==", user_doc_id).stream()
        space_ids = {doc.to_dict()["space_id"] for doc in docs}
        if not space_ids:
            return []
        space_refs = [db.collection("spaces").document(sid) for sid in space_ids]
        space_docs = db.get_all(space_refs)
        for doc in space_docs:
            if doc.exists:
                data = doc.to_dict()
                space = SpaceResponseSchema(id=doc.id,name=data["space_name"],created_at=data.get("created_at"))
                spaces.append(space)
        
        return spaces
        

    except Exception as e:
        print("Error fetching ", str(e))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")
    



def join_space(space_model: CreateSpaceModel, db, user_id: str):
    
    try:
        space_doc = db.collection("spaces").where("space_name", "==", space_model.space_name).stream()
        target_space_id = None
        for doc in space_doc:
            space_data = doc.to_dict()
            if verify_password(space_model.space_password, space_data["space_password"]):
                target_space_id = doc.id
                break
        if not target_space_id:
            raise HTTPException(status_code=401, detail="Invalid Credentials")
    

    # Creating membership this will keep log of all joins of the user with the space.
        member_ref = db.collection("membership").document(f"{user_id}_{target_space_id}")
        if member_ref.get().exists:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already a member of the space")
    

        member_ref.set({
        "user_id": user_id,
        "space_id": target_space_id,
        "joined_at": firestore.SERVER_TIMESTAMP,
        "status": "active"
    })
        return SpaceResponseSchema(id=target_space_id,name=space_model.space_name)
    except Exception as e:
        print("Error joining space: ", str(e))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Internal Server Error")
        


def get_images(user_id, db, space_id):
    try:
        # 1. Fetch appearance records
        # Use a set to avoid duplicate image fetches
        image_ids = set()
        docs = (
            db.collection("appearances")
            .where("face_id", "==", user_id)
            .where("space_id", "==", space_id)
            .stream()
        )

        for doc in docs:
            image_ids.add(doc.get("image_id"))
        
        if not image_ids:
            return []

        # 2. Bulk Fetch Images (Faster and Cheaper)
        image_urls = []
        # Firestore's get_all is much faster than a loop
        image_refs = [db.collection("images").document(img_id) for img_id in image_ids]
        image_docs = db.get_all(image_refs)

        for doc in image_docs:
            if doc.exists:
                data = doc.to_dict()
                image_urls.append(ImagesResponseSchema(
                    id=doc.id,
                    file_name=data.get("filename"),
                    uploaded_at=data.get("created_at"),
                    url=data.get("url")
                ))
        
       
        return image_urls

    except Exception as e:
        
        print(f"Error fetching images: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")