import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration
      return const FirebaseOptions(
        apiKey: "AIzaSyChkHZ9laaDhT2HyehfDiBzyozL7oLBui8",
        authDomain: "flutter-article-manager.firebaseapp.com",
        projectId: "flutter-article-manager",
        storageBucket: "flutter-article-manager.appspot.com",
        messagingSenderId: "874202647978",
        appId: "1:874202647978:web:1d65f57c687bbae3edefd3",
        measurementId: "G-073ECFN0GK"
      );
    }
    
    // Add configurations for other platforms as needed
    // For now, use web configuration as fallback
    return const FirebaseOptions(
      apiKey: "AIzaSyChkHZ9laaDhT2HyehfDiBzyozL7oLBui8",
      authDomain: "flutter-article-manager.firebaseapp.com",
      projectId: "flutter-article-manager",
      storageBucket: "flutter-article-manager.appspot.com",
      messagingSenderId: "874202647978",
      appId: "1:874202647978:web:1d65f57c687bbae3edefd3",
      measurementId: "G-073ECFN0GK"
    );
  }
}
