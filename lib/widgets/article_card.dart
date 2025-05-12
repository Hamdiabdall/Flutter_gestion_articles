import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/article.dart';
import '../services/article_service.dart';
import '../services/auth_service.dart';
import '../screens/article/edit_article_screen.dart';
import '../screens/home/home_screen.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });
  
  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _hasUserLiked = false;
  bool _isDeleting = false; // Track deletion state
  final ArticleService _articleService = ArticleService();
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _checkIfUserLiked();
  }
  
  Future<void> _checkIfUserLiked() async {
    final hasLiked = await _articleService.hasUserLikedArticle(widget.article.id);
    if (mounted) {
      setState(() {
        _hasUserLiked = hasLiked;
      });
    }
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    
    // First confirm the user wants to delete
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Delete Article'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this article? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldDelete || !context.mounted) return;
    
    // Show the loading state
    setState(() {
      _isDeleting = true;
    });
    
    try {
      // Implement a simpler, direct approach to delete the article
      await _articleService.deleteArticle(widget.article.id);
      
      // Success!
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Important: We need to give the Firestore time to update before refreshing
        // Use a direct approach to completely rebuild the home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()), 
          (route) => false,
        );
      }
    } catch (error) {
      // Error handling
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        
        // Show error message with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Could not delete article: ${error.toString().replaceAll('Exception: ', '')}'),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: _isDeleting
          ? _buildDeletingState(theme)
          : InkWell(
              onTap: widget.onTap,
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (widget.article.imageUrl != null)
              _buildArticleImage(widget.article.imageUrl!, theme),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.article.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Content preview
                  Text(
                    widget.article.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Footer: author, date, and owner actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Author info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.person, 
                              size: 16, 
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.article.authorName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            timeago.format(widget.article.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Owner actions
                          if (widget.article.authorId == _authService.currentUser?.uid)
                            PopupMenuButton(
                              icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Text('Edit'),
                                  onTap: () {
                                    // Use Future.delayed because PopupMenuItem's onTap doesn't support Context operations
                                    Future.delayed(Duration.zero, () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditArticleScreen(article: widget.article),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          // Refresh article data
                                          _checkIfUserLiked();
                                        }
                                      });
                                    });
                                  },
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: theme.colorScheme.error, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                                    ],
                                  ),
                                  onTap: () {
                                    // Use a short delay to allow the menu to close first
                                    Future.delayed(const Duration(milliseconds: 50), () {
                                      if (context.mounted) {
                                        _showDeleteConfirmation(context);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Likes and comments
                  Row(
                    children: [
                      // Like indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _hasUserLiked 
                            ? theme.colorScheme.primary.withOpacity(0.15) 
                            : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasUserLiked ? Icons.favorite : Icons.favorite_border, 
                              size: 18, 
                              color: _hasUserLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.article.likeCount}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _hasUserLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                fontWeight: _hasUserLiked ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Comment indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.comment_outlined, 
                              size: 18, 
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.article.commentCount}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Building a loading state overlay for when article is being deleted
  Widget _buildDeletingState(ThemeData theme) {
    return Container(
      height: widget.article.imageUrl != null ? 400 : 200,
      width: double.infinity,
      color: theme.colorScheme.surface.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Deleting article...',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleImage(String imageUrl, ThemeData theme) {
    // Common image dimensions
    const imageHeight = 200.0;
    
    // Common error widget
    Widget errorWidget = Container(
      height: imageHeight,
      width: double.infinity,
      color: theme.colorScheme.primaryContainer.withOpacity(0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: theme.colorScheme.onPrimaryContainer,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
    
    // Check if image URL is base64
    if (imageUrl.startsWith('data:image')) {
      // Decode base64 image
      try {
        final imageData = imageUrl.split(',')[1];
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.memory(
            base64Decode(imageData),
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => errorWidget,
          ),
        );
      } catch (e) {
        return errorWidget;
      }
    } else {
      // Regular URL image
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: imageHeight,
            width: double.infinity,
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          errorWidget: (context, url, error) => errorWidget,
        ),
      );
    }
  }
}
