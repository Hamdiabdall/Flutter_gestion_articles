import 'dart:async';
import 'dart:io';
import '../models/article.dart';

/// A mock implementation of ArticleService for platforms where Firebase is not supported
class MockArticleService {
  // Empty list - no default articles
  final List<Article> _articles = [];

  // Get all articles
  Stream<List<Article>> getArticles() {
    return Stream.value(_articles);
  }

  // Get a specific article
  Stream<Article?> getArticle(String articleId) {
    return Stream.value(_articles.firstWhere(
      (article) => article.id == articleId,
      orElse: () => throw Exception('Article not found'),
    ));
  }

  // Create a new article
  Future<Article> createArticle({
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    File? imageFile,
  }) async {
    // Generate a new ID based on the current timestamp
    final String articleId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create article object with mock data
    final article = Article(
      id: articleId,
      authorId: authorId,
      authorName: authorName,
      title: title,
      content: content,
      imageUrl: imageFile != null ? 'https://picsum.photos/seed/$articleId/800/600' : null,
      createdAt: DateTime.now(),
    );

    // Add to the mock list
    _articles.insert(0, article);

    return article;
  }

  // Update an existing article
  Future<void> updateArticle({
    required String articleId,
    String? title,
    String? content,
    File? imageFile,
  }) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index == -1) {
      throw Exception('Article not found');
    }

    final currentArticle = _articles[index];
    final updatedArticle = currentArticle.copyWith(
      title: title ?? currentArticle.title,
      content: content ?? currentArticle.content,
      imageUrl: imageFile != null ? 'https://picsum.photos/seed/$articleId/800/600' : currentArticle.imageUrl,
    );

    _articles[index] = updatedArticle;
  }

  // Delete an article
  Future<void> deleteArticle(String articleId) async {
    _articles.removeWhere((article) => article.id == articleId);
  }

  // Increment like count
  Future<void> likeArticle(String articleId) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = _articles[index];
      _articles[index] = article.copyWith(likeCount: article.likeCount + 1);
    }
  }

  // Update comment count
  Future<void> updateCommentCount(String articleId, int change) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = _articles[index];
      _articles[index] = article.copyWith(
        commentCount: article.commentCount + change,
      );
    }
  }
}
