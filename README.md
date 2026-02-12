# GrabPic
GrabPic is an AI-powered application that solves the "needle in a haystack" problem of finding yourself in thousands of event photos.

Instead of scrolling through endless Google Drive folders, attendees simply take a selfie, and the system uses facial recognition and vector search to instantly retrieve every photo they appear in.

# 🚀 Features
Smart Indexing: Organizers upload bulk photos; the system automatically detects and indexes every face.

Privacy-First Search: Users find their photos using a live selfie (biometric anchor) rather than text search.

High Performance: Uses Vector Embeddings for sub-second search speeds across thousands of images.

Event Spaces: Isolated environments for different events (Weddings, Conferences, Meetups).


Tech Stack
Backend: Python (FastAPI)

Database (Metadata): MongoDB (Stores Event & Photo details)

Vector Store: ChromaDB (Stores Face Embeddings for search)
