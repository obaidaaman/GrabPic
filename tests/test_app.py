import streamlit as st
import requests
import os
from dotenv import load_dotenv
load_dotenv()


API_BASE_URL = "http://127.0.0.1:8000" 

st.set_page_config(page_title="GrabPic AI Tester", page_icon="📸")
st.title("📸 GrabPic Organizer Tester")
st.markdown("Test the **Signed URL + Background AI** flow.")


space_id = st.text_input("Enter Space ID", value="wedding_test_01")
uploaded_files = st.file_uploader("Choose photos", accept_multiple_files=True, type=['jpg', 'jpeg', 'png'])

if st.button("Start Bulk Upload & Process"):
    if not uploaded_files:
        st.error("Please select some files first.")
    else:
        filenames = [file.name for file in uploaded_files]
        
      
        st.info("Step 1: Requesting Signed URLs from FastAPI...")
        payload = {"fileName": filenames, "space_id": space_id}
        
        try:
            resp = requests.post(f"{API_BASE_URL}/files/get-presigned-url", json=payload)
            resp.raise_for_status()
            url_data = resp.json()["urls"]
            
            storage_paths = []
            progress_bar = st.progress(0)
            
           
            st.info("Step 2: Uploading files directly to Firebase Storage...")
            for i, file_info in enumerate(url_data):
                signed_url = file_info['signed_url']
                target_path = file_info['storage_path']
                
             
                original_file = next(f for f in uploaded_files if f.name == file_info['original_name'])
                
              
                upload_resp = requests.put(
                    signed_url, 
                    data=original_file.getvalue(),
                    headers={"Content-Type": "image/jpeg"} 
                )
                
                if upload_resp.status_code == 200 or upload_resp.status_code == 201:
                    storage_paths.append(target_path)
                    st.write(f"✅ Uploaded: {file_info['original_name']}")
                else:
                    st.error(f"❌ Failed to upload {file_info['original_name']}")
                    st.code(upload_resp.text)
                
                progress_bar.progress((i + 1) / len(url_data))

     
            if storage_paths:
                st.info("Step 3: Notifying FastAPI to start AI processing...")
               
                process_payload = storage_paths 
                
               
                final_resp = requests.post(
                    f"{API_BASE_URL}/files/upload", 
                    json=storage_paths, 
                    params={"space_id": space_id}
                )
                
                if final_resp.status_code == 201 or final_resp.status_code == 200:
                    st.success("🎉 Success! Background processing has started.")
                    st.json(final_resp.json())
                else:
                    st.error(f"Backend processing failed: {final_resp.text}")

        except Exception as e:
            st.error(f"An error occurred: {str(e)}")