import 'dart:async';
import '../models/user.dart';

/// A mock implementation of AuthService for platforms where Firebase is not supported
class MockAuthService {
  // Mock user data
  final AppUser _mockUser = AppUser(
    id: 'mock-user-id',
    name: 'Test User',
    email: 'test@example.com',
    photoUrl: null,
  );
  
  // Authentication state
  bool _isAuthenticated = true;
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  
  // Constructor
  MockAuthService() {
    // Initialize with authenticated state
    _authStateController.add(_isAuthenticated);
  }
  
  // Simulate auth state changes
  Stream<bool> get authStateChanges => _authStateController.stream;
  
  // Get current user
  AppUser? get currentUser => _isAuthenticated ? _mockUser : null;
  
  // Sign in with email and password (mock)
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    
    // Set as authenticated
    _isAuthenticated = true;
    _authStateController.add(_isAuthenticated);
  }
  
  // Register with email and password (mock)
  Future<void> registerWithEmailAndPassword(String name, String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Simple validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('Name, email, and password cannot be empty');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    // Set as authenticated
    _isAuthenticated = true;
    _authStateController.add(_isAuthenticated);
  }
  
  // Sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isAuthenticated = false;
    _authStateController.add(_isAuthenticated);
  }
  
  // Get user data
  Future<AppUser?> getUserData(String uid) async {
    return _mockUser;
  }
  
  // Clean up resources
  void dispose() {
    _authStateController.close();
  }
}
