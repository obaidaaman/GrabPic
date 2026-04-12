# Configuration Guide

## Backend URL Configuration

The most important configuration is setting up the correct backend URL.

### Development (Local)

When running locally, edit `lib/utils/constants.dart`:

```dart
class AppConstants {
  static const String baseUri = 'http://localhost:8000';
  // ...
}
```

### Production

When deploying to production, update the URL:

```dart
class AppConstants {
  static const String baseUri = 'https://your-backend-domain.com';
  // ...
}
```

## Environment-Specific Configuration

For managing different environments, you can create separate constant files:

```
lib/utils/
├── constants.dart          # Base constants
├── constants_dev.dart      # Development URLs
├── constants_prod.dart     # Production URLs
└── constants.stg.dart      # Staging URLs
```

## CORS Configuration

Make sure your backend has CORS enabled for your frontend domain. In your FastAPI backend (`services/api/main.py`), the CORS is already configured with:

```python
origins = [
    "*"
]
```

For production, you should restrict this to your actual domain:

```python
origins = [
    "https://your-frontend-domain.com",
    "https://www.your-frontend-domain.com",
]
```

## Camera Permissions

### HTTPS Requirement

Most browsers require HTTPS for camera access. The only exception is `localhost` for development.

### Browser Support

| Browser | Camera Support | Notes |
|---------|---------------|-------|
| Chrome | ✅ Full | Recommended |
| Edge | ✅ Full | Recommended |
| Firefox | ✅ Full | |
| Safari | ⚠️ Limited | May require user interaction |

## Building for Production

1. Update `baseUri` to your production backend URL
2. Build the web app:
   ```bash
   flutter build web --release
   ```
3. Deploy `build/web/` to your hosting service

## Hosting Options

### Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Select build/web as public directory
firebase deploy
```

### Vercel

```bash
npm install -g vercel
cd build/web
vercel
```

### Netlify

```bash
npm install -g netlify-cli
cd build/web
netlify deploy
```

### GitHub Pages

```bash
# Add to pubspec.yaml deploy script
flutter build web --release
# Push build/web to gh-pages branch
```

## Troubleshooting

### Camera not accessible

1. Ensure HTTPS (except localhost)
2. Check browser permissions
3. Try a different browser

### API connection failed

1. Verify `baseUri` is correct
2. Check CORS settings on backend
3. Ensure backend is running

### Build errors

```bash
flutter clean
flutter pub get
flutter build web --release
```
