import 'dart:async';
import '../models/comment.dart';

/// A mock implementation of CommentService for platforms where Firebase is not supported
class MockCommentService {
  // Mock data - a map of articleId to list of comments
  final Map<String, List<Comment>> _commentsByArticle = {
    '1': [
      Comment(
        id: 'c1',
        articleId: '1',
        authorId: 'mock-user-2',
        authorName: 'Jane Smith',
        content: 'Great introduction to Flutter! Very helpful for beginners.',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      Comment(
        id: 'c2',
        articleId: '1',
        authorId: 'mock-user-3',
        authorName: 'Alex Johnson',
        content: 'Could you share more examples of Flutter widgets?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Comment(
        id: 'c3',
        articleId: '1',
        authorId: 'mock-user-4',
        authorName: 'Sarah Williams',
        content: 'I found this really helpful for my project. Thanks!',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
    '2': [
      Comment(
        id: 'c4',
        articleId: '2',
        authorId: 'mock-user-1',
        authorName: 'John Doe',
        content: 'Firebase is a game-changer for mobile app development.',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      Comment(
        id: 'c5',
        articleId: '2',
        authorId: 'mock-user-3',
        authorName: 'Alex Johnson',
        content: 'How does Firebase handle offline data syncing?',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ],
    '3': [
      Comment(
        id: 'c6',
        articleId: '3',
        authorId: 'mock-user-2',
        authorName: 'Jane Smith',
        content: 'Provider is my favorite state management solution.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  // Get comments for a specific article
  Stream<List<Comment>> getComments(String articleId) {
    final comments = _commentsByArticle[articleId] ?? [];
    return Stream.value(List.from(comments));
  }

  // Add a new comment
  Future<Comment> addComment({
    required String articleId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    // Generate a new ID based on the current timestamp
    final String commentId = 'c${DateTime.now().millisecondsSinceEpoch}';
    
    // Create comment object
    final comment = Comment(
      id: commentId,
      articleId: articleId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    );

    // Initialize the article's comment list if it doesn't exist
    if (!_commentsByArticle.containsKey(articleId)) {
      _commentsByArticle[articleId] = [];
    }

    // Add to the mock list
    _commentsByArticle[articleId]!.insert(0, comment);

    return comment;
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String articleId) async {
    if (_commentsByArticle.containsKey(articleId)) {
      _commentsByArticle[articleId]!.removeWhere((comment) => comment.id == commentId);
    }
  }
}
