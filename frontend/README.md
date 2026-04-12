# GrabPic Frontend (Flutter Web)

A Flutter web application for GrabPic AI - a face recognition photo retrieval system.

## Features

- **Face Authentication**: Login or create an account using facial recognition
- **Camera Integration**: Take selfies directly from the browser or upload from gallery
- **Space Management**: Create and join event spaces
- **Photo Upload**: Upload multiple photos with progress tracking
- **Gallery View**: View all photos where you appear in each space

## Prerequisites

- Flutter SDK 3.1.0 or higher
- A web browser with camera support (Chrome, Edge, Firefox)
- Backend API running (services/api)

## Setup

### 1. Configure Backend URL

Edit `lib/utils/constants.dart` and change the `baseUri`:

```dart
class AppConstants {
  static const String baseUri = 'https://your-backend-url.com';
  // ... rest of the file
}
```

### 2. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 3. Run on Web

```bash
flutter run -d chrome
```

Or build for production:

```bash
flutter build web --release
```

The built files will be in `build/web/`.

## Camera Permissions

The app requires camera permissions for face authentication. When running on localhost, most browsers will allow camera access. For production:

- **HTTPS is required** for camera access on most browsers
- Make sure your backend URL uses HTTPS when deploying

## Architecture

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── auth_model.dart
│   ├── space_model.dart
│   ├── image_model.dart
│   └── job_status_model.dart
├── providers/             # State management (Provider)
│   ├── auth_provider.dart
│   ├── space_provider.dart
│   └── image_provider.dart
├── screens/               # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── create_space_screen.dart
│   ├── join_space_screen.dart
│   ├── gallery_screen.dart
│   └── upload_screen.dart
├── services/              # API & Storage services
│   ├── api_service.dart
│   └── storage_service.dart
└── utils/                 # Constants and utilities
    └── constants.dart
```

## API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/face-auth` | POST | Face authentication |
| `/users/create-space` | POST | Create event space |
| `/users/get-spaces` | GET | Get user's spaces |
| `/users/join-space` | POST | Join existing space |
| `/users/get-images` | GET | Get user's photos |
| `/files/url` | POST | Get presigned upload URLs |
| `/files/upload` | POST | Trigger background processing |
| `/files/status` | GET | Check job status |

## State Management

The app uses the **Provider** package for state management:

- **AuthProvider**: Handles face authentication and user session
- **SpaceProvider**: Manages event spaces (create, join, list)
- **ImageProvider**: Handles photo upload and gallery

## Troubleshooting

### Camera not working
- Ensure browser has camera permissions
- Use HTTPS in production (required for camera access)
- Try a different browser (Chrome/Edge recommended)

### API connection errors
- Verify `baseUri` in `lib/utils/constants.dart`
- Check CORS settings on your backend
- Ensure backend is running and accessible

### Build fails
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK is 3.1.0 or higher
- Check for dependency conflicts

## Deployment

1. Build the web app:
   ```bash
   flutter build web --release
   ```

2. Deploy `build/web/` to your hosting service (Vercel, Netlify, Firebase Hosting, etc.)

3. Update `baseUri` to point to your production backend

## License

MIT
