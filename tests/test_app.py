import streamlit as st
import requests
import os
from dotenv import load_dotenv

load_dotenv()

API_BASE_URL = "http://127.0.0.1:8000"

st.set_page_config(page_title="GrabPic AI", page_icon="📸", layout="wide")

if "jwt" not in st.session_state:
    st.session_state.jwt = None
if "user_id" not in st.session_state:
    st.session_state.user_id = None
if "my_spaces" not in st.session_state:
    st.session_state.my_spaces = []

def get_auth_header():
    return {"Authorization": f"Bearer {st.session_state.jwt}"} if st.session_state.jwt else {}

def refresh_spaces():
    if st.session_state.jwt:
        resp = requests.get(f"{API_BASE_URL}/users/get-spaces", headers=get_auth_header())
        if resp.status_code == 200:
            st.session_state.my_spaces = resp.json()

st.title("📸 GrabPic AI Portal")

with st.sidebar:
    st.header("👤 Authentication")
    
    if not st.session_state.jwt:
        st.warning("Please upload a selfie to Login or Register.")
        is_organiser = st.checkbox("I am an Organiser")
        img_file = st.file_uploader("Upload a clear selfie", type=['jpg', 'jpeg', 'png'])
        
        if img_file:
            st.image(img_file, caption="Selfie Preview", width=150)
            if st.button("Authenticate with Face"):
                files = {"file": (img_file.name, img_file.getvalue(), img_file.type)}
                params = {"is_organiser": is_organiser}
                with st.spinner("Analyzing facial features..."):
                    try:
                        resp = requests.post(f"{API_BASE_URL}/auth/face-auth", files=files, params=params)
                        if resp.status_code == 200:
                            data = resp.json()
                            st.session_state.jwt = data["token"]
                            st.session_state.user_id = data["id"]
                            refresh_spaces()
                            st.success(f"Verified! {data['message']}")
                            st.rerun()
                        else:
                            st.error(f"Authentication failed: {resp.text}")
                    except Exception as e:
                        st.error(f"Connection Error: {e}")
    else:
        st.success("Authenticated ✅")
        st.info(f"User ID: {st.session_state.user_id[:8]}...")
        if st.button("Refresh My Data"):
            refresh_spaces()
        if st.button("Logout"):
            st.session_state.jwt = None
            st.session_state.user_id = None
            st.session_state.my_spaces = []
            st.rerun()

tab1, tab2, tab3, tab4 = st.tabs(["🚀 Create Space", "🔑 Join Space", "📤 Upload Photos", "🖼 My Gallery"])

with tab1:
    st.subheader("Create a New Event Space")
    if not st.session_state.jwt:
        st.info("Please login via the sidebar first.")
    else:
        name = st.text_input("Space Name", key="create_name")
        pw = st.text_input("Space Password", type="password", key="create_pw")
        if st.button("Create Space"):
            payload = {"space_name": name, "space_password": pw, "created_by": st.session_state.user_id}
            resp = requests.post(f"{API_BASE_URL}/users/create-space", json=payload, headers=get_auth_header())
            if resp.status_code == 201:
                st.success(f"Space created! ID: {resp.json()['id']}")
                refresh_spaces()
            else:
                st.error(resp.text)

with tab2:
    st.subheader("Join an Existing Space")
    if not st.session_state.jwt:
        st.info("Please login via the sidebar first.")
    else:
        j_name = st.text_input("Space Name", key="join_name")
        j_pw = st.text_input("Space Password", type="password", key="join_pw")
        if st.button("Join Space"):
            payload = {"space_name": j_name, "space_password": j_pw, "created_by": ""}
            resp = requests.post(f"{API_BASE_URL}/users/join-space", json=payload, headers=get_auth_header())
            if resp.status_code == 200:
                st.success("Successfully joined the space!")
                refresh_spaces()
            else:
                st.error("Failed to join. Check credentials.")

with tab3:
    st.subheader("Collaborative Upload")
    if not st.session_state.jwt:
        st.info("Please login via the sidebar.")
    elif not st.session_state.my_spaces:
        st.warning("You haven't joined or created any spaces yet.")
    else:
        space_options = {s['name']: s['id'] for s in st.session_state.my_spaces}
        selected_space_name = st.selectbox("Select Space to Upload", options=list(space_options.keys()))
        selected_space_id = space_options[selected_space_name]
        
        uploaded_files = st.file_uploader("Select photos", accept_multiple_files=True, type=['jpg', 'jpeg', 'png'])

        if st.button("🚀 Start Bulk Upload"):
            if uploaded_files:
                try:
                    filenames = [file.name for file in uploaded_files]
                    payload = {"fileName": filenames, "space_id": selected_space_id}
                    
                    resp = requests.post(f"{API_BASE_URL}/files/get-presigned-url", json=payload, headers=get_auth_header())
                    resp.raise_for_status()
                    url_data = resp.json()["urls"]
                    
                    storage_paths = []
                    progress_bar = st.progress(0)
                    status_text = st.empty()
                    
                    for i, file_info in enumerate(url_data):
                        signed_url = file_info['signed_url']
                        target_path = file_info['storage_path']
                        orig_name = file_info['original_name']
                        original_file = next(f for f in uploaded_files if f.name == orig_name)
                        
                        status_text.text(f"Uploading: {orig_name}")
                        upload_resp = requests.put(signed_url, data=original_file.getvalue(), headers={"Content-Type": "image/jpeg"})
                        
                        if upload_resp.status_code in [200, 201]:
                            storage_paths.append(target_path)
                        progress_bar.progress((i + 1) / len(url_data))

                    if storage_paths:
                        final_resp = requests.post(f"{API_BASE_URL}/files/upload", json=storage_paths, params={"space_id": selected_space_id}, headers=get_auth_header())
                        if final_resp.status_code in [200, 201]:
                            st.balloons()
                            st.success("Processing started in background!")
                except Exception as e:
                    st.error(f"Error: {str(e)}")

with tab4:
    st.subheader("Your Spottings")
    if not st.session_state.jwt:
        st.info("Login to see your photos.")
    elif not st.session_state.my_spaces:
        st.warning("Join a space to see photos.")
    else:
        space_options = {s['name']: s['id'] for s in st.session_state.my_spaces}
        target_space_name = st.selectbox("Select Space to View Gallery", options=list(space_options.keys()))
        target_space_id = space_options[target_space_name]

        if st.button("Find My Photos"):
            resp = requests.get(f"{API_BASE_URL}/users/get-images", params={"space_id": target_space_id}, headers=get_auth_header())
            if resp.status_code == 200:
                images = resp.json()
                if not images:
                    st.warning("No photos found of you here yet.")
                else:
                    cols = st.columns(3)
                    for idx, img in enumerate(images):
                        with cols[idx % 3]:
                            st.image(img['url'], use_container_width=True, caption=img['file_name'])
            else:
                st.error("Error fetching images.")