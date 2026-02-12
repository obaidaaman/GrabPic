from src.models.models import CreateSpaceModel
from google.cloud import firestore
from fastapi import HTTPException, status

def create_space(create_space_model: CreateSpaceModel, user_id, db):
    try:
        user_doc = db.collection("users").document(
            create_space_model.user_doc_id
        ).get()

        if not user_doc.exists:
            return {"status": "Failed", "error": "User does not exist"}
        space_doc = db.collection("spaces").document()
        space_doc.set({
            "user_doc_id": user_id,
            "space_name": create_space_model.space_name,
            "created_by": create_space_model.created_by,
            "created_at": firestore.SERVER_TIMESTAMP
        })

        return {"status": "Success", "message": "Space created", "space_id": space_doc.id}

    except Exception as e:
        return {"status": "Error", "message": str(e)}

def get_spaces(user_doc_id, db):
    try:
        spaces = []
        collection = db.collection("spaces")
        docs = collection.where("user_doc_id", "==", user_doc_id).stream()
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            spaces.append(data)
        if not spaces:
            return {"status": "Success", "spaces": []}
        return {"status": "Success", "spaces": spaces}
        

    except HTTPException:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)