import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/article.dart';
import '../../models/comment.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../../services/comment_service.dart';
import '../../widgets/comment_item.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ArticleService _articleService = ArticleService();
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        await _commentService.addComment(
          articleId: widget.articleId,
          authorId: user.uid,
          authorName: userData?.name ?? user.email?.split('@')[0] ?? 'Anonymous',
          content: _commentController.text.trim(),
        );

        if (mounted) {
          _commentController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  Future<void> _likeArticle() async {
    try {
      await _articleService.likeArticle(widget.articleId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking article: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
      ),
      body: StreamBuilder<Article?>(
        stream: _articleService.getArticle(widget.articleId),
        builder: (context, articleSnapshot) {
          if (articleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (articleSnapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${articleSnapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final article = articleSnapshot.data;
          if (article == null) {
            return const Center(child: Text('Article not found'));
          }

          return Column(
            children: [
              // Article content - scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Author and date
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            article.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            timeago.format(article.createdAt),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Image if present
                      if (article.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: article.imageUrl!.startsWith('data:image') 
                            // Handle base64 encoded image
                            ? Image.memory(
                                base64Decode(article.imageUrl!.split(',')[1]),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              )
                            // Handle regular URL images
                            : CachedNetworkImage(
                                imageUrl: article.imageUrl!,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Content
                      Text(
                        article.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                      
                      // Likes and comments count
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up),
                              onPressed: _likeArticle,
                              color: Colors.blue,
                            ),
                            Text('${article.likeCount}'),
                            const SizedBox(width: 16),
                            const Icon(Icons.comment, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${article.commentCount}'),
                          ],
                        ),
                      ),
                      
                      const Divider(),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Comments
                      StreamBuilder<List<Comment>>(
                        stream: _commentService.getComments(widget.articleId),
                        builder: (context, commentSnapshot) {
                          if (commentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (commentSnapshot.hasError) {
                            return Text(
                              'Error: ${commentSnapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            );
                          }

                          final comments = commentSnapshot.data ?? [];

                          if (comments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No comments yet. Be the first to comment!',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return CommentItem(
                                comment: comment,
                                currentUserId: _authService.currentUser?.uid ?? '',
                                onDelete: () async {
                                  try {
                                    await _commentService.deleteComment(
                                      comment.id,
                                      widget.articleId,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error deleting comment: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Add comment section - fixed at bottom
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isPostingComment
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send),
                      onPressed: _isPostingComment ? null : _addComment,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
