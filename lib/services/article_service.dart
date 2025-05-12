import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/article.dart';
import 'firebase_service.dart';
import 'mock_article_service.dart';

class ArticleService {
  // Singleton instance
  static final ArticleService _instance = ArticleService._internal();

  // Factory constructor to return the singleton instance
  factory ArticleService() => _instance;

  // Firestore instance
  FirebaseFirestore? _firestore;
  
  // UUID generator for creating unique IDs
  final Uuid _uuid = const Uuid();

  // Mock service for platforms where Firebase isn't available
  final MockArticleService _mockService = MockArticleService();
  
  // Check if we should use mock implementation
  bool get _useMock => !FirebaseService.isFirebaseSupported;

  // Create the ArticleService singleton instance
  ArticleService._internal() {
    // Initialize Firebase services if not running in a mock environment
    if (!_useMock) {
      _firestore = FirebaseFirestore.instance;
      // No longer using Firebase Storage since we're storing images in Firestore
    }
  }

  // Get all articles
  Stream<List<Article>> getArticles() {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.getArticles();
    }
    
    // Use Firebase for supported platforms
    return _firestore!
        .collection('articles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Article.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get a specific article
  Stream<Article?> getArticle(String articleId) {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.getArticle(articleId);
    }
    
    // Use Firebase for supported platforms
    return _firestore!
        .collection('articles')
        .doc(articleId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Article.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Create a new article
  Future<Article> createArticle({
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    File? imageFile,
  }) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.createArticle(
        authorId: authorId,
        authorName: authorName,
        title: title,
        content: content,
        imageFile: imageFile,
      );
    }
    
    // Generate a unique ID for the article
    final String articleId = _uuid.v4();
    String? imageUrl;

    // Upload image if provided
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, articleId);
    }

    // Create article object
    final article = Article(
      id: articleId,
      authorId: authorId,
      authorName: authorName,
      title: title,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    // Save article to Firestore
    await _firestore!.collection('articles').doc(articleId).set(article.toFirestore());

    return article;
  }

  // Create a new article with a web image
  Future<Article> createArticleWeb({
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    Uint8List? webImageBytes,
  }) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.createArticle(
        authorId: authorId,
        authorName: authorName,
        title: title,
        content: content,
        imageFile: null, // Mock doesn't need to differentiate between web and mobile
      );
    }
    
    // Generate a unique ID for the article
    final String articleId = _uuid.v4();
    String? imageUrl;

    // Upload web image if provided
    if (webImageBytes != null) {
      imageUrl = await _uploadWebImage(webImageBytes, articleId);
    }

    // Create article object
    final article = Article(
      id: articleId,
      authorId: authorId,
      authorName: authorName,
      title: title,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    // Save article to Firestore
    await _firestore!.collection('articles').doc(articleId).set(article.toFirestore());

    return article;
  }

  // Update an existing article
  Future<void> updateArticle({
    required String articleId,
    String? title,
    String? content,
    File? imageFile,
  }) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.updateArticle(
        articleId: articleId,
        title: title,
        content: content,
        imageFile: imageFile,
      );
    }
    
    // Get the current article data
    final docSnapshot = await _firestore!.collection('articles').doc(articleId).get();
    if (!docSnapshot.exists) {
      throw Exception('Article not found');
    }

    // Prepare updates
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;

    // Upload new image if provided
    if (imageFile != null) {
      final String imageUrl = await _uploadImage(imageFile, articleId);
      updates['imageUrl'] = imageUrl;
    }
    
    // Update article in Firestore (only if there are updates to make)
    if (updates.isNotEmpty) {
      await _firestore!.collection('articles').doc(articleId).update(updates);
    }
  }
  
  // Update an existing article with web image
  Future<void> updateArticleWeb({
    required String articleId,
    String? title,
    String? content,
    Uint8List? webImageBytes,
  }) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.updateArticle(
        articleId: articleId,
        title: title,
        content: content,
        imageFile: null,
      );
    }
    
    // Get the current article data
    final docSnapshot = await _firestore!.collection('articles').doc(articleId).get();
    if (!docSnapshot.exists) {
      throw Exception('Article not found');
    }

    // Prepare updates
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;

    // Upload new web image if provided
    if (webImageBytes != null) {
      final String imageUrl = await _uploadWebImage(webImageBytes, articleId);
      updates['imageUrl'] = imageUrl;
    }

    // Update article in Firestore
    await _firestore!.collection('articles').doc(articleId).update(updates);
  }

  // Delete an article
  Future<void> deleteArticle(String articleId) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      print('Using mock service for deleteArticle');
      return _mockService.deleteArticle(articleId);
    }
    
    try {
      print('Starting article deletion process for ID: $articleId');
      
      // Get the current user ID for permission check
      final currentUserId = FirebaseService.auth!.currentUser?.uid;
      if (currentUserId == null) {
        print('Error: No user logged in');
        throw Exception('You must be logged in to delete an article');
      }
      
      print('Current user ID: $currentUserId');
      
      // Get the article to confirm it exists and check ownership
      final articleRef = _firestore!.collection('articles').doc(articleId);
      final docSnapshot = await articleRef.get();
      
      if (!docSnapshot.exists) {
        print('Error: Article not found');
        throw Exception('Article not found');
      }
      
      // Check if current user is the article author
      final articleData = docSnapshot.data() as Map<String, dynamic>;
      final authorId = articleData['authorId'] as String;
      
      print('Article author ID: $authorId');
      
      if (authorId != currentUserId) {
        print('Error: Permission denied - user is not the article author');
        throw Exception('Permission denied: You can only delete your own articles');
      }
      
      // Directly delete the article first (most important operation)
      print('Deleting article document');
      await articleRef.delete();
      print('Article document deleted successfully');
      
      // Now handle likes and comments (can be done after article is deleted)
      try {
        print('Finding and deleting related likes');
        final likesSnapshot = await _firestore!
            .collection('articleLikes')
            .where('articleId', isEqualTo: articleId)
            .get();
            
        print('Found ${likesSnapshot.docs.length} likes to delete');
        
        // Delete likes one by one to avoid batch size limits
        for (var doc in likesSnapshot.docs) {
          await doc.reference.delete();
        }
        
        print('All likes deleted successfully');
      } catch (error) {
        // Log but don't throw - the article is already deleted
        print('Warning: Failed to delete some article likes: $error');
      }
      
      try {
        print('Finding and deleting related comments');
        final commentsSnapshot = await _firestore!
            .collection('comments')
            .where('articleId', isEqualTo: articleId)
            .get();
            
        print('Found ${commentsSnapshot.docs.length} comments to delete');
        
        // Delete comments one by one to avoid batch size limits
        for (var doc in commentsSnapshot.docs) {
          await doc.reference.delete();
        }
        
        print('All comments deleted successfully');
      } catch (error) {
        // Log but don't throw - the article is already deleted
        print('Warning: Failed to delete some article comments: $error');
      }
      
      print('Article deletion completed successfully');
    } catch (error) {
      print('Error in deleteArticle: $error');
      throw Exception('Failed to delete article: $error');
    }
  }

  // Convert image file to base64 string for Firestore storage
  Future<String> _uploadImage(File imageFile, String articleId) async {
    if (_useMock) {
      // Return a placeholder URL for mock implementation
      return 'https://picsum.photos/seed/$articleId/800/600';
    }
    
    try {
      // Read the file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Check if the image is too large for Firestore (< 900KB to be safe)
      if (bytes.length > 900 * 1024) {
        // Resize the image if it's too large
        // This requires the 'image' package which you may need to add to pubspec.yaml
        // For now, we'll just return an error
        throw Exception('Image too large for Firestore. Please use an image smaller than 900KB.');
      }
      
      // Convert to base64
      final base64Image = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      rethrow;
    }
  }

  // Convert web image bytes to base64 string for Firestore storage
  Future<String> _uploadWebImage(Uint8List webImageBytes, String articleId) async {
    if (_useMock) {
      // Return a placeholder URL for mock implementation
      return 'https://picsum.photos/seed/$articleId/800/600';
    }
    
    try {
      // Check if the image is too large for Firestore (< 900KB to be safe)
      if (webImageBytes.length > 900 * 1024) {
        // Resize the image if it's too large
        // This requires the 'image' package which you may need to add to pubspec.yaml
        // For now, we'll just return an error
        throw Exception('Image too large for Firestore. Please use an image smaller than 900KB.');
      }
      
      // Convert to base64
      final base64Image = base64Encode(webImageBytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      rethrow;
    }
  }

  // No need to delete images from storage as they're now part of the Firestore document
  Future<void> deleteImage(String imageUrl, String articleId) async {
    if (_useMock || !imageUrl.startsWith('data:image')) {
      // Skip deletion for mock URLs or non-base64 images
      return;
    }
    
    // No need to do anything here, as the image is deleted when the article is deleted
    // Just keeping this method for API compatibility
    return;
  }

  // Increment like count - ensuring users can only like once
  Future<void> likeArticle(String articleId) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.likeArticle(articleId);
    }
    
    try {
      // Need current user ID to track likes
      final userId = FirebaseService.auth!.currentUser?.uid;
      if (userId == null) {
        throw Exception('User must be logged in to like an article');
      }
      
      // Create a unique ID for the like document based on userId and articleId
      final likeId = '$userId-$articleId';
      
      // Check if the user has already liked this article
      final likeDoc = await _firestore!.collection('articleLikes').doc(likeId).get();
      
      // If user already liked the article, do nothing
      if (likeDoc.exists) {
        return;
      }
      
      // First check if the article exists to avoid permission issues
      final articleDoc = await _firestore!.collection('articles').doc(articleId).get();
      if (!articleDoc.exists) {
        throw Exception('Article not found');
      }
      
      // Create the like document first, as this has fewer permission requirements
      await _firestore!.collection('articleLikes').doc(likeId).set({
        'userId': userId,
        'articleId': articleId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Then update the article's like count
      await _firestore!.collection('articles').doc(articleId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Provide more detailed error message for permission issues
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Permission denied. This is likely due to Firebase security rules. ' +
          'Please ensure you have proper Firebase rules configured for the articleLikes collection.'
        );
      }
      rethrow;
    }
  }

  // Check if user has liked an article
  Future<bool> hasUserLikedArticle(String articleId) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return false; // Mock always returns false for now
    }
    
    // Need current user ID to check likes
    final userId = FirebaseService.auth!.currentUser?.uid;
    if (userId == null) {
      return false; // Not logged in = not liked
    }
    
    // Create a unique ID for the like document based on userId and articleId
    final likeId = '$userId-$articleId';
    
    // Check if the like document exists
    final likeDoc = await _firestore!.collection('articleLikes').doc(likeId).get();
    return likeDoc.exists;
  }

  // Update comment count
  Future<void> updateCommentCount(String articleId, int change) async {
    // Use mock implementation for unsupported platforms
    if (_useMock) {
      return _mockService.updateCommentCount(articleId, change);
    }
    
    await _firestore!.collection('articles').doc(articleId).update({
      'commentCount': FieldValue.increment(change),
    });
  }
}
