import uuid
import cv2
import numpy as np
from fastapi import FastAPI, UploadFile, File
from typing import List
from insightface.app import FaceAnalysis


# 1. Initialize AI Model
face_app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
face_app.prepare(ctx_id=0, det_size=(640, 640))
local_registry = [] 
SIMILARITY_THRESHOLD = 1.0 

def calculate_distance(emb1, emb2):
 
    return np.linalg.norm(emb1 - emb2)


async def upload_photos(contents : bytes, fileName:str):
    results = []
    
    
        
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
    faces = face_app.get(img)
    detected_in_this_photo = []

    for face in faces:
            new_emb = face.normed_embedding
            matched_user_id = None
            
            
            best_dist = float('inf')
            for record in local_registry:
                dist = calculate_distance(new_emb, record["embedding"])
                if dist < SIMILARITY_THRESHOLD and dist < best_dist:
                    best_dist = dist
                    matched_user_id = record["user_id"]

            if matched_user_id:
               
                detected_in_this_photo.append({
                    "user_id": matched_user_id, 
                    "status": "existing",
                    "distance": round(float(best_dist), 2) 
                })
            else:
                
                new_id = str(uuid.uuid4())[:8]
                local_registry.append({
                    "user_id": new_id,
                    "embedding": new_emb
                })
                detected_in_this_photo.append({"user_id": new_id, "status": "new"})
        
    results.append({
            "filename": fileName,
            "mappings": detected_in_this_photo
        })

    return results