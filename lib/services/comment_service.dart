import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment.dart';
import 'article_service.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ArticleService _articleService = ArticleService();
  final Uuid _uuid = const Uuid();

  // Get comments for a specific article
  Stream<List<Comment>> getComments(String articleId) {
    // Option 1: Retrieve comments without sorting (works while index is building)
    return _firestore
        .collection('comments')
        .where('articleId', isEqualTo: articleId)
        // .orderBy('createdAt', descending: true) // Commented out until index is ready
        .snapshots()
        .map((snapshot) {
      var comments = snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort comments client-side instead (temporary solution)
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }

  // Add a new comment
  Future<Comment> addComment({
    required String articleId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    // Generate a unique ID for the comment
    final String commentId = _uuid.v4();

    // Create comment object
    final comment = Comment(
      id: commentId,
      articleId: articleId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    );

    // Save comment to Firestore
    await _firestore.collection('comments').doc(commentId).set(comment.toFirestore());
    
    // Update comment count on the article
    await _articleService.updateCommentCount(articleId, 1);

    return comment;
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String articleId) async {
    await _firestore.collection('comments').doc(commentId).delete();
    
    // Update comment count on the article
    await _articleService.updateCommentCount(articleId, -1);
  }
}
