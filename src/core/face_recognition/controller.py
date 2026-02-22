from datetime import datetime, timezone, timedelta
import os
import uuid
import cv2
from google.cloud import firestore
import numpy as np
from qdrant_client.models import  PointStruct, VectorParams, Distance
from typing import List
import logging
from fastapi.concurrency import run_in_threadpool
from dotenv import load_dotenv
load_dotenv()
logger = logging.getLogger(__name__)

async def run_bulk_ai_processing(paths, space_id, face_app, qdrant, db, bucket):
    """
    Worker function that processes images one by one in the background.
    """
    if not qdrant.collection_exists("faces_collection"):
         qdrant.create_collection(
        collection_name="faces_collection",
        vectors_config=VectorParams(size=512, distance=Distance.COSINE),
    )
      
    for path in paths:
        try:
            
            blob = bucket.blob(path)
            content_bytes = blob.download_as_bytes()

            
            await upload_photos(
                face_app=face_app,
                contents=content_bytes,
                client=qdrant,
                db=db,
                fileName=path.split("/")[-1],
                space_id=space_id,
                storage_path=path
            )
            logger.info(f"Background: Processed {path}")
            
        except Exception as e:
            logger.error(f"Background Error processing {path}: {str(e)}")



# face_app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
# face_app.prepare(ctx_id=0, det_size=(640, 640))



# Check if the face embedding exists in the DB or not, if yes then fetch that uid only or else create new vector and get that id.

#
async def upload_photos(face_app, contents : bytes, client, db , fileName:str, space_id:str, storage_path:str):
    
    """
      Check if the face embedding exists in the DB or not, 
      if yes then fetch that uid only       OR
        else create new vector and get that id.      
        """
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
    faces = await run_in_threadpool(face_app.get, img)
    if not faces:
         return {"filename": fileName, "status" : "No faces detected"}
    
    image_id = str(uuid.uuid4())
    bucket_name = os.getenv("STORAGE_BUCKET_NAME")
    public_url = f"https://storage.googleapis.com/{bucket_name}/{storage_path}"
    bucket_name = os.getenv("STORAGE_BUCKET_NAME")
    # This is created to map to which space does the image belongs, along with its url.
    image_ref = db.collection("images").document(image_id)
    image_ref.set({
        "filename": fileName,
        "space_id": space_id,
        "url" : public_url,
        "storage_path": storage_path,
        "created_at": firestore.SERVER_TIMESTAMP
    })
    detected_faces_summary = []
                                  
    
    
    
    for face in faces:
            new_emb = face.normed_embedding.tolist()
            search_results = client.query_points(
            collection_name="faces_collection",
            query=new_emb,
            # query_filter=Filter(
            #     must=[FieldCondition(key="space_id", match=MatchValue(value=space_id))]
            # ),
            limit=1,
            score_threshold=0.65  
        )
            status = "existing"
            if search_results.points:
                 print("Quadrant results:", search_results)
                 face_id = search_results.points[0].id
                 
            else:
                 face_id = str(uuid.uuid4())
                 status = "new"
                 client.upsert(collection_name="faces_collection",wait=True,points=[
                 PointStruct(id=face_id,vector=new_emb,payload={"space_id": space_id })])
                 db.collection("users").document(face_id).set({
                 "face_id": face_id,
                "first_seen": datetime.now(timezone.utc),
                "space_id": space_id
            })
            
           
            # That image ID is mapped to that face ID in the appearances collection, along with the timestamp of when it was detected.
           # Linking face_id to image_id
            db.collection("appearances").add({
            "face_id": face_id,
            "image_id": image_id,
            "space_id": space_id,
            "detected_at": datetime.now(timezone.utc)
                })
            detected_faces_summary.append({"face_id": face_id, "status": status})   
    return {
                 "image_id": image_id,
                "matches_found": len(detected_faces_summary),
                "details": detected_faces_summary
            }
            
           
            

async def get_signed_urls(filenames: List[str], space_id : str, bucket):
     response_data =[]
     for name in filenames:
        file_extension = name.split(".")[-1]
        unique_name = f"{uuid.uuid4()}.{file_extension}"
        storage_path = f"spaces/{space_id}/uploads/{unique_name}"
            
            # 2. Generate the Signed URL (Valid for 15 mins)
        blob = bucket.blob(storage_path)
        signed_url = blob.generate_signed_url(
                version="v4",
                expiration=timedelta(minutes=15),
                method="PUT",
                content_type="image/jpeg"
              
            )
# Storarge path is client will send again through process.
        response_data.append({
                "original_name": name,
                "signed_url": signed_url,
                "storage_path": storage_path ,
                
                
            })
     return {"urls" : response_data}            
            