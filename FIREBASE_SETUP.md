# Firebase Configuration Guide for Gestion Article App

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Create a Firebase Project](#create-a-firebase-project)
3. [Register Your Flutter App with Firebase](#register-your-flutter-app-with-firebase)
4. [Add Firebase Configuration Files](#add-firebase-configuration-files)
5. [Initialize Firebase in Flutter](#initialize-firebase-in-flutter)
6. [Set Up Firebase Services](#set-up-firebase-services)
   - [Authentication](#authentication)
   - [Firestore Database](#firestore-database)
   - [Storage](#storage)
7. [Deploy Firestore Security Rules](#deploy-firestore-security-rules)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

Before configuring Firebase, make sure you have:

- Flutter SDK installed and configured
- An active Google account
- Firebase CLI installed (optional, for deploying rules)

## Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create project"
3. Enter a project name (e.g., "Gestion Article")
4. Choose whether to enable Google Analytics (recommended)
5. Select your Analytics account or create a new one
6. Click "Create project"
7. Wait for the project to be created

## Register Your Flutter App with Firebase

### Android App Configuration

1. In the Firebase Console, select your project
2. Click the Android icon (🤖) to add an Android app
3. Enter your app's package name: `com.example.gestion_article`
   - You can find this in `android/app/build.gradle` or `android/app/src/main/AndroidManifest.xml`
4. Enter an app nickname (optional, e.g., "Gestion Article")
5. Enter the SHA-1 signing certificate (optional for debug, required for some Firebase services)
   - To get the debug certificate, run: `cd android && ./gradlew signingReport`
6. Click "Register app"
7. Download the `google-services.json` file

### iOS App Configuration (Optional)

1. In the Firebase Console, in your project, click the iOS icon (🍎) to add an iOS app
2. Enter your app's bundle ID (e.g., `com.example.gestionArticle`)
   - Found in your Xcode project settings or `ios/Runner.xcodeproj/project.pbxproj`
3. Enter an app nickname (optional)
4. Enter the App Store ID (optional)
5. Click "Register app"
6. Download the `GoogleService-Info.plist` file

## Add Firebase Configuration Files

### For Android

1. Move the downloaded `google-services.json` file to your Flutter project's `android/app/` directory
2. Update your project-level `android/build.gradle` file to include the Google services plugin:

```gradle
buildscript {
    dependencies {
        // ... other dependencies
        classpath 'com.google.gms:google-services:4.3.15' // Use the latest version
    }
}
```

3. Update your app-level `android/app/build.gradle` file to apply the plugin:

```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services' // Add this line
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
```

### For iOS (Optional)

1. Move the downloaded `GoogleService-Info.plist` to your Flutter project's `ios/Runner` directory
2. Open Xcode, right-click on the Runner project, and select "Add Files to 'Runner'"
3. Select the `GoogleService-Info.plist` file and ensure "Copy items if needed" is checked
4. Click "Add"

## Initialize Firebase in Flutter

1. Add Firebase dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase Core is required for all Firebase services
  firebase_core: ^2.32.0
  # Add other Firebase packages as needed
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.5
  firebase_storage: ^11.7.7
```

2. Run `flutter pub get` to install the dependencies

3. Initialize Firebase in your `main.dart` file:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Your app code...
}
```

## Set Up Firebase Services

### Authentication

1. In the Firebase Console, go to "Authentication" > "Sign-in method"
2. Enable the sign-in methods you want to use (Email/Password, Google, etc.)
3. For Email/Password:
   - Toggle the "Email/Password" option to enable it
   - Configure settings if needed (password strength, email verification)
4. Save your changes

#### Implementation in Flutter:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }
  
  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
  
  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }
}
```

### Firestore Database

1. In the Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose start mode (production or test)
4. Select a database location (choose the closest to your users)
5. Wait for the database to be provisioned

#### Database Structure for Gestion Article

```
/users/{userId}
  - name: string
  - email: string
  - createdAt: timestamp

/articles/{articleId}
  - authorId: string (reference to user)
  - authorName: string
  - title: string
  - content: string
  - imageUrl: string (optional)
  - createdAt: timestamp
  - likeCount: number
  - commentCount: number

/comments/{commentId}
  - articleId: string (reference to article)
  - authorId: string (reference to user)
  - authorName: string
  - content: string
  - createdAt: timestamp

/articleLikes/{likeId}
  - articleId: string (reference to article)
  - userId: string (reference to user)
  - createdAt: timestamp
```

#### Implementation in Flutter:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all articles
  Stream<List<Article>> getArticles() {
    return _firestore
        .collection('articles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Article.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
  
  // Create a new article
  Future<void> createArticle(Article article) {
    return _firestore.collection('articles').doc(article.id).set(article.toFirestore());
  }
}
```

### Storage

1. In the Firebase Console, go to "Storage"
2. Click "Get started"
3. Choose security rules (production or test)
4. Select a storage location (choose the closest to your users)
5. Wait for storage to be provisioned

#### Implementation in Flutter (for image uploads):

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload image and get download URL
  Future<String> uploadImage(File imageFile, String path) async {
    final reference = _storage.ref().child(path);
    final uploadTask = reference.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }
}
```

## Deploy Firestore Security Rules

Create a file named `firestore.rules` in your project's `firebase` directory:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Function to check if user is the owner of a resource
    function isOwner(resource) {
      return isAuthenticated() && request.auth.uid == resource.data.authorId;
    }
    
    // Users collection rules
    match /users/{userId} {
      // Anyone can read user profiles
      allow read: if true;
      // Users can only create/update their own profiles
      allow create, update: if isAuthenticated() && request.auth.uid == userId;
      // Only admin can delete user profiles
      allow delete: if false;
    }
    
    // Articles collection rules
    match /articles/{articleId} {
      allow read: if true;
      // Allow authenticated users to create articles
      allow create: if isAuthenticated();
      // Allow only the article author to update or delete
      allow update, delete: if isAuthenticated() && request.auth.uid == resource.data.authorId;
    }
    
    // Allow authenticated users to like articles once
    match /articleLikes/{likeId} {
      allow read: if true;
      allow create: if isAuthenticated() && 
                     !exists(/databases/$(database)/documents/articleLikes/$(request.auth.uid + '_' + request.resource.data.articleId));
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.userId;
    }
    
    // Comments collection rules
    match /comments/{commentId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && request.auth.uid == resource.data.authorId;
    }
  }
}
```

Deploy the rules using the Firebase CLI:

1. Install the Firebase CLI if you haven't already: `npm install -g firebase-tools`
2. Log in to Firebase: `firebase login`
3. Initialize your project: `firebase init firestore`
4. Deploy the rules: `firebase deploy --only firestore:rules`

## Troubleshooting

### Common Issues and Solutions

1. **Gradle Build Fails**
   - Ensure you have the latest Google services plugin
   - Check that your `google-services.json` is in the correct location
   - Update Gradle and its dependencies

2. **Missing Dependencies**
   - Run `flutter clean` followed by `flutter pub get`
   - Check for conflicting dependencies in pubspec.yaml

3. **Authentication Errors**
   - Check if the authentication method is enabled in Firebase Console
   - Verify network connectivity
   - Look for any restrictions in Firebase Auth settings

4. **Firestore Permission Denied**
   - Check your security rules
   - Verify user authentication state
   - Ensure you're following the data structure

5. **Image Upload Failures**
   - Verify Storage rules allow uploads
   - Check image size (Firestore documents have a 1MB limit)
   - For larger images, use Firebase Storage instead of base64 in Firestore
