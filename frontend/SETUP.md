# GrabPic Frontend - Setup Guide

## Quick Start

### 1. Install Flutter

If you don't have Flutter installed:

```bash
# Windows (using Chocolatey)
choco install flutter

# macOS (using Homebrew)
brew install flutter

# Linux
sudo snap install flutter --classic
```

Verify installation:
```bash
flutter doctor
```

### 2. Setup Project

```bash
cd frontend
flutter pub get
```

### 3. Configure Backend URL

Edit `lib/utils/constants.dart`:

```dart
static const String baseUri = 'http://localhost:8000';  // Change this to your backend URL
```

### 4. Run the App

```bash
flutter run -d chrome
```

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── providers/             # State management
│   ├── screens/               # UI screens
│   ├── services/              # API services
│   └── utils/                 # Constants
├── web/
│   ├── index.html             # Web entry point
│   ├── manifest.json          # PWA manifest
│   └── icons/                 # App icons
├── pubspec.yaml               # Dependencies
└── README.md                  # Documentation
```

## Features

### 1. Face Authentication
- Take a selfie using browser camera
- Upload photo from gallery
- Automatic user creation or login

### 2. Space Management
- Create event spaces with passwords
- Join existing spaces
- View all your spaces

### 3. Photo Upload
- Select multiple photos
- Direct upload to cloud storage via presigned URLs
- Progress tracking
- Background processing

### 4. Gallery
- View photos where you appear
- Filter by space
- Full-screen image view

## API Integration

The frontend connects to these backend endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/face-auth` | POST | Face authentication |
| `/users/create-space` | POST | Create space |
| `/users/get-spaces` | GET | List spaces |
| `/users/join-space` | POST | Join space |
| `/users/get-images` | GET | Get user images |
| `/files/url` | POST | Get presigned URLs |
| `/files/upload` | POST | Trigger processing |
| `/files/status` | GET | Job status |

## Dependencies

Key packages used:

- `provider` - State management
- `http` / `dio` - HTTP client
- `camera` - Camera access
- `image_picker` - Photo selection
- `shared_preferences` - Local storage
- `google_fonts` - Typography

## Common Issues

### Camera Permission Denied

1. Ensure you're using HTTPS (or localhost)
2. Grant camera permission in browser
3. Try a different browser

### API Connection Failed

1. Check `baseUri` in constants.dart
2. Verify backend is running
3. Check CORS settings

### Build Fails

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

## Building for Production

```bash
flutter build web --release
```

Deploy the `build/web/` folder to your hosting service.

## Next Steps

1. Start your backend API
2. Run `flutter run -d chrome`
3. Take a selfie to authenticate
4. Create or join a space
5. Upload photos and view results!
