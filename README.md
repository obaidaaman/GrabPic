# GrabPic
GrabPic is an AI-powered application that solves the "needle in a haystack" problem of finding yourself in thousands of event photos.

Instead of scrolling through endless Google Drive folders, attendees simply take a selfie, and the system uses facial recognition and vector search to instantly retrieve every photo they appear in.

# 🚀 Features
Smart Indexing

Organizers upload bulk photos and the system automatically detects, embeds, and indexes every face.

Privacy-First Search

Users find their photos using a live selfie (biometric anchor) instead of text search.

Event Spaces

Isolated environments for different events such as weddings, conferences, and meetups.

Async AI Processing

Photo embedding runs in the background using a distributed job queue — ensuring fast uploads without blocking.

Scalable Architecture

Face processing is handled by independent workers, allowing the system to scale horizontally for large events.

High Performance Retrieval

Uses vector embeddings for sub-second search across thousands of images.




# System Architecture

GrabPic uses an event-driven asynchronous microservices architecture to separate user interaction from compute-heavy AI processing.

Client
  ↓
API (FastAPI)
  ↓
Redis Job Queue (Upstash)
  ↓
Worker Service
  ↓
Face Processing Service
  ↓
Vector Store (QdrantDB)

# Tech Stack
Backend
Python (FastAPI)

Metadata Database
Firebase
Stores:
  Event data

  Image metadata

  User references

Vector Store
QdrantDB
Stores:

  Face embeddings for similarity search



Message Queue
Upstash Redis
Used for:
  Background AI job processing



AI / CV
InsightFace
Used for:

  Face detection & embedding
