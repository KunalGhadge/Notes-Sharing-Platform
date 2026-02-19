# Developer Guide - NoteHub

This document provides an overview of the NoteHub project from a developer's perspective, covering performance, design, and security analysis, along with guidelines for future development.

## Project Overview
NoteHub is a Flutter-based mobile application for sharing and accessing study notes, supported by a Django + MongoDB backend.

## 1. Performance Analysis
- **State Management**: Uses `GetX` for reactive state management. It's efficient for this scale but requires careful management of controller lifecycles.
- **Local Database**: `Hive` is used for fast, NoSQL local storage. It is excellent for performance-critical mobile applications.
- **Image Handling**: `cached_network_image` is utilized to cache remote images, reducing bandwidth usage and improving UI responsiveness.
- **Visual Feedback**: Shimmer effects and Lottie animations are implemented to improve perceived performance during data fetching.
- **Networking**: The app uses both `http` and `dio`. Recommendation: Standardize on `dio` for its superior feature set (interceptors, better error handling).

## 2. Design & Architecture
- **Pattern**: Follows a Model-View-Controller (MVC) architectural pattern, providing a clean separation between business logic and UI.
- **UI Framework**: Built with Material 3, ensuring a modern look and feel.
- **Asset Management**: Good use of SVGs and Lottie for high-quality, scalable graphics.
- **Backend Design**: Django REST Framework handles API requests, while MongoDB with GridFS is used for efficient storage of large document files.
- **Modularization**: The codebase is well-structured into `core`, `model`, `view`, `controller`, and `service` directories.

## 3. Security Analysis (Action Required)
Several critical security vulnerabilities have been identified and must be addressed:

- **Authentication Vulnerability**: The system currently lacks secure session management (e.g., JWT). Many API endpoints rely solely on a `username` passed from the client, which allows for trivial impersonation.
- **Password Storage**: Evidence suggests passwords are stored in plain text or without strong hashing in the database. **Action**: Implement BCrypt or Argon2 hashing immediately.
- **Data Exposure**: Sensitive user information is stored in Hive without encryption.
- **API Security**: The backend URL is hardcoded in the frontend. In production, use environment variables and ensure all communication is over HTTPS.
- **Hardcoded Secrets**: Check for any hardcoded MongoDB connection strings or API keys in the backend `config.py` (which should be moved to `.env`).

## 4. Development Guidelines

### Environment Setup
1.  **Frontend**:
    ```bash
    cd notehub
    flutter pub get
    ```
2.  **Backend**:
    ```bash
    cd server
    # Note: requirements.txt may be UTF-16 encoded; ensure your editor handles this.
    pip install -r requirements.txt
    python manage.py migrate
    ```

### Testing
- **Flutter**: Run `flutter test` in the `notehub` directory.
- **Backend**: Run `python manage.py test` in the `server` directory.

### Future Roadmap
1.  **Security Overhaul**: Implement JWT authentication and secure password hashing.
2.  **Unified Networking**: Migrate all `http` calls to `dio` with a base client configuration.
3.  **Error Handling**: Implement a global error handling strategy in the Flutter app.
4.  **CI/CD**: Set up GitHub Actions for automated testing and linting.

---
*Created by Jules, AI Software Engineer.*
