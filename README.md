# Gestion Article - Flutter App

A Flutter application for managing articles with Firebase backend integration. The app allows users to create, read, update, and delete articles, upload images, comment on articles, and more.

## Features

- **User Authentication**: Sign up, login, and profile management
- **Article Management**: Create, view, edit, and delete articles
- **Image Upload**: Add images to articles from camera or gallery
- **Comments**: Comment on articles and view other users' comments
- **Likes**: Like and unlike articles
- **Dark/Light Theme**: Toggle between dark and light themes

## Technologies Used

- **Frontend**: Flutter
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider/Flutter's built-in state management
- **Image Handling**: Image Picker, Cached Network Image

## Getting Started

### Prerequisites

- Flutter SDK (latest version recommended)
- Dart SDK (latest version recommended)
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Hamdiabdall/Flutter_gestion_articles.git
   cd Flutter_gestion_articles
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Set up a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
   - Add an Android app to your Firebase project (use package name: com.example.gestion_article)
   - Download the `google-services.json` file and place it in the `android/app/` directory
   - Follow the detailed Firebase setup instructions in the `FIREBASE_SETUP.md` file

4. **Run the app**
   ```bash
   flutter run
   ```

### Cloning & Setting Up After Push to GitHub

1. **Clone the project**
   ```bash
   git clone https://github.com/Hamdiabdall/Flutter_gestion_articles.git
   cd Flutter_gestion_articles
   ```

2. **Setting Up After Cloning**
   - Install Flutter dependencies:
     ```bash
     flutter pub get
     ```
     
   - Firebase Configuration:
     - Ensure `google-services.json` is in `android/app/`
     - For iOS: Ensure `GoogleService-Info.plist` is in `ios/Runner/`
     - If these files aren't in the repository, download them from Firebase console
     
   - Configure Firebase Access:
     - Follow the Firebase setup guide in `FIREBASE_SETUP.md`
     - You might need to add your new development device's SHA-1 key to Firebase
     
   - Build and Run:
     ```bash
     flutter run
     ```

## Common Issues After Cloning

1. **Missing Firebase Configuration**:
   - Check that your configuration files are correctly placed
   - The Firebase project might need to be reconfigured for new environments

2. **Auth Issues**:
   - Verify authentication methods are enabled in Firebase Console
   - For Android, verify the SHA-1 key is added to Firebase

3. **Image Upload Not Working**:
   - Verify Firebase Storage rules allow uploads from new devices/users

4. **Dependency Issues**:
   - If you have package conflicts, run `flutter clean` followed by `flutter pub get`

## Project Structure

- `lib/`
  - `models/` - Data models
  - `screens/` - UI screens
  - `services/` - API and Firebase services
  - `widgets/` - Reusable UI components
  - `utils/` - Utility functions
  - `main.dart` - Entry point

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

