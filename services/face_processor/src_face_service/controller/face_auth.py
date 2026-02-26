from fastapi import  HTTPException, status
import cv2
import numpy as np

def process_embedding(contents: bytes, face_app):
    try:
        
        nparr = np.frombuffer(contents,np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)


        face = face_app.get(img)[0] 
        
        if not face:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Face not Found")
        embedding = face.normed_embedding.tolist()
        return {
            "status" : "Success",
            "embedding" : embedding 
        }
    except Exception as e:
        print("An exception is found:", str(e))
        raise HTTPException(status_code=500, detail="Internal Server Error")
