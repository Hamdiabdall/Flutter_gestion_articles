import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool get isFirebaseSupported => kIsWeb || Platform.isAndroid || Platform.isIOS;
  
  // Firebase Auth instance
  static FirebaseAuth? get auth => isFirebaseSupported ? FirebaseAuth.instance : null;
  
  // Firestore instance
  static FirebaseFirestore? get firestore => isFirebaseSupported ? FirebaseFirestore.instance : null;
  
  static Future<void> initializeFirebase() async {
    if (!isFirebaseSupported) {
      debugPrint('Firebase is not supported on this platform, using mock implementation');
      return;
    }
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }
}
