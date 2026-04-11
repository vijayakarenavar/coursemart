# CourseMart Student App 📚

A Flutter-based student application for accessing courses, watching lectures, and downloading notes. Built with production-ready architecture and best practices.

## Features ✨

- **Authentication**: Secure login with JWT token storage
- **Course Dashboard**: View enrolled courses with progress tracking
- **Lecture Player**: YouTube video integration for lecture playback
- **Notes Download**: Download and view PDF lecture notes
- **Profile Management**: View student profile and change password
- **Offline Caching**: Local cache for improved performance
- **Auto-Logout**: Automatic session management on token expiry

## Tech Stack 🛠️

- **Framework**: Flutter 3.x (Null-safe)
- **State Management**: Provider
- **HTTP Client**: Dio with interceptors
- **Secure Storage**: flutter_secure_storage for JWT tokens
- **Video Player**: youtube_player_flutter
- **Image Caching**: cached_network_image
- **Local Cache**: Hive
- **Environment Config**: flutter_dotenv

## Project Structure 📁

```
lib/
├── config/                    # Configuration files
│   ├── api_config.dart       # API endpoints and constants
│   └── env_loader.dart       # Environment variable loader
│
├── models/                    # Data models
│   ├── student.dart          # Student profile model
│   ├── course.dart           # Course model
│   └── lecture.dart          # Lecture model
│
├── services/                  # API and network services
│   ├── api_service.dart      # Main API service with all endpoints
│   ├── secure_storage.dart   # JWT token secure storage
│   ├── network_helper.dart   # Network connectivity checker
│   └── interceptors.dart     # Dio interceptors (auth, logging, retry)
│
├── providers/                 # State management (Provider)
│   ├── auth_provider.dart    # Authentication state
│   ├── course_provider.dart  # Courses list state
│   └── lecture_provider.dart # Lectures list state
│
├── screens/                   # App screens/pages
│   ├── auth/
│   │   └── login_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── course/
│   │   └── course_details_screen.dart
│   ├── lecture/
│   │   └── video_player_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── change_password_screen.dart
│
├── widgets/                   # Reusable UI components
│   ├── course_card.dart      # Course card with progress
│   ├── lecture_tile.dart     # Lecture list tile
│   ├── status_badge.dart     # Video status badge
│   ├── filter_chip.dart      # Filter chips for courses
│   └── empty_state.dart      # Empty/error state widgets
│
├── utils/                     # Utility helpers
│   ├── error_handler.dart    # Error handling and display
│   ├── download_manager.dart # File download manager
│   ├── date_helper.dart      # Date formatting utilities
│   └── cache_manager.dart    # Local cache management
│
└── main.dart                  # App entry point
```

## Getting Started 🚀

### Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart SDK 3.11.0 or higher
- Android Studio / VS Code with Flutter extensions
- An Android/iOS device or emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd coursemart
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Setup environment variables**

   ```bash
   # Copy the example env file
   cp .env.example .env

   # Edit .env with your configuration
   ```

4. **Configure .env file**

   ```env
   # Production API
   API_BASE_URL=https://course.mart.lemmecode.com/api/v1

   # OR Development API (uncomment for local testing)
   # API_BASE_URL=http://localhost:8000/api/v1

   MEDIA_BASE_URL=https://course.mart.lemmecode.com
   APP_ENV=development
   STORAGE_KEY_AUTH_TOKEN=auth_token
   ```

5. **Run the app**

   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios

   # For web
   flutter run -d chrome
   ```

## API Endpoints 🔌

The app integrates with the following CourseMart APIs:

| Method | Endpoint                               | Description          | Auth |
| ------ | -------------------------------------- | -------------------- | ---- |
| POST   | `/api/v1/auth/login`                   | Student login        | ❌   |
| POST   | `/api/v1/auth/logout`                  | Logout               | ✅   |
| POST   | `/api/v1/auth/change-password`         | Change password      | ✅   |
| GET    | `/api/v1/student/profile`              | Get student profile  | ✅   |
| GET    | `/api/v1/student/courses`              | Get enrolled courses | ✅   |
| GET    | `/api/v1/student/courses/:id/lectures` | Get course lectures  | ✅   |
| GET    | `/api/v1/student/lectures/:id`         | Get lecture details  | ✅   |

## Architecture 🏗️

### Clean Architecture Pattern

The app follows clean architecture principles:

1. **Presentation Layer**: Screens and widgets
2. **Business Logic Layer**: Providers for state management
3. **Data Layer**: Services and API clients
4. **Domain Layer**: Models and entities

### State Management

Uses **Provider** pattern for state management:

- `AuthProvider`: Manages authentication state, login/logout
- `CourseProvider`: Manages courses list, filtering, caching
- `LectureProvider`: Manages lectures for selected course

### Security

- **JWT Tokens**: Stored securely using `flutter_secure_storage`
- **Auto-interceptors**: All API requests automatically include auth token
- **Auto-logout**: 401 errors trigger automatic logout
- **Environment Variables**: Sensitive data in `.env` (not committed)

## Video Status Badges 🎨

Lectures display status with color-coded badges:

- ✅ **Ready** (Green): Video ready to watch
- ⏳ **Processing** (Orange): Video being processed
- ❌ **Failed** (Red): Video upload failed
- 🔵 **Uploading** (Blue): Video being uploaded

## Testing 🧪

### Run tests

```bash
flutter test
```

### Run with coverage

```bash
flutter test --coverage
```

## Building for Production 📦

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## Troubleshooting 🔧

### Common Issues

**Issue: `.env file not found`**

- Solution: Copy `.env.example` to `.env` in the project root

**Issue: `Token expired` errors**

- Solution: Logout and login again to get fresh token

**Issue: YouTube videos not playing**

- Solution: Check internet connection and video ID validity

**Issue: PDF download fails**

- Solution: Check storage permissions in Android/iOS manifest

### Network Debug

Enable detailed network logging by setting `APP_ENV=development` in `.env`. The app logs all API requests/responses in debug mode.

## Dependencies 📚

Key dependencies from `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.4.0 # HTTP client
  flutter_secure_storage: ^9.0.0 # Secure token storage
  flutter_dotenv: ^5.1.0 # Environment variables
  provider: ^6.1.1 # State management
  youtube_player_flutter: ^9.0.1 # YouTube video player
  cached_network_image: ^3.3.0 # Image caching
  open_file: ^3.3.2 # File opener
  path_provider: ^2.1.1 # Path utilities
  hive: ^2.2.3 # Local cache
  intl: ^0.19.0 # Date formatting
```

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Code Quality Standards ✅

- Null-safety enabled
- Detailed inline comments
- Error handling for all API calls
- Loading states for async operations
- Responsive UI design
- Production-ready code

## Future Enhancements 🚀

- [ ] Push notifications for new lectures
- [ ] Offline mode with video downloads
- [ ] Dark mode support
- [ ] Search and filter lectures
- [ ] Lecture progress tracking
- [ ] Discussion forums
- [ ] Quiz integration

## License 📄

This project is proprietary software. All rights reserved.

## Support 💬

For API-related issues, contact the backend team.
For Flutter/app issues, open an issue in the repository.

---

**Built with ❤️ using Flutter**
