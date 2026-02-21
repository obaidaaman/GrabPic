import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
load_dotenv()

cred = credentials.Certificate(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))

# cred = credentials.Certificate("credentials.json")

# firebase_admin.initialize_app(cred)

db = "firestore.client()"

def get_db():
    return db