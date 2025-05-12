import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/article.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../../utils/image_helper.dart';
import '../home/home_screen.dart';

class EditArticleScreen extends StatefulWidget {
  final Article article;

  const EditArticleScreen({super.key, required this.article});

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _articleService = ArticleService();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.article.title;
    _contentController.text = widget.article.content;
    
    // If article has an image and it's a base64 image, preload it
    if (widget.article.imageUrl != null && widget.article.imageUrl!.startsWith('data:image')) {
      try {
        final imageData = widget.article.imageUrl!.split(',')[1];
        if (kIsWeb) {
          ImageHelper.webImage = base64Decode(imageData);
        }
        // For mobile, we'd need to save to a temporary file but we'll skip that for now
      } catch (e) {
        // Failed to preload image, just continue
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final success = await ImageHelper.pickImageFromGallery();
      if (success) {
        setState(() {
          _imageChanged = true;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to pick image: $error';
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      final success = await ImageHelper.takePhoto();
      if (success) {
        setState(() {
          _imageChanged = true;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to take picture: $error';
      });
    }
  }

  void _removeImage() {
    setState(() {
      ImageHelper.clearImage();
      _imageChanged = true;
    });
  }

  Future<void> _updateArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = _authService.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Check if this user owns the article
        if (user.uid != widget.article.authorId) {
          throw Exception('You do not have permission to edit this article');
        }

        // Handle image upload for web and mobile differently
        if (kIsWeb) {
          if (_imageChanged) {
            await _articleService.updateArticleWeb(
              articleId: widget.article.id,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              webImageBytes: ImageHelper.webImage,
            );
          } else {
            await _articleService.updateArticleWeb(
              articleId: widget.article.id,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
            );
          }
        } else {
          if (_imageChanged) {
            await _articleService.updateArticle(
              articleId: widget.article.id,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              imageFile: ImageHelper.pickedFile,
            );
          } else {
            await _articleService.updateArticle(
              articleId: widget.article.id,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
            );
          }
        }

        if (mounted) {
          // Clear any previous snackbars
          ScaffoldMessenger.of(context).clearSnackBars();
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article updated successfully')),
          );
          
          // Return success and refresh the parent screen
          Navigator.pop(context, true);
          
          // Delay slightly to ensure UI is updated smoothly
          Future.delayed(Duration(milliseconds: 300), () {
            if (!mounted) return;
            
            // Refresh parent widgets
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
          // Provide a more user-friendly error message
          if (error.toString().contains('permission-denied')) {
            _errorMessage = 'Permission denied: You do not have permission to edit this article.';
          } else if (error.toString().contains('network')) {
            _errorMessage = 'Network error: Please check your internet connection.';
          } else {
            _errorMessage = 'Failed to update article: $error';
          }
        });
        
        // Show error in snackbar as well for better visibility
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Article'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  color: theme.colorScheme.error,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onError),
                    ),
                  ),
                ),
              ),
            
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter article title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            
            // Content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Enter article content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            
            // Image section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Article Image',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (ImageHelper.hasPickedImage() || 
                        (widget.article.imageUrl != null && !_imageChanged))
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ImageHelper.hasPickedImage()
                              ? kIsWeb && ImageHelper.webImage != null
                                  ? Image.memory(
                                      ImageHelper.webImage!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      ImageHelper.pickedFile!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                              : widget.article.imageUrl!.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(widget.article.imageUrl!.split(',')[1]),
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      widget.article.imageUrl!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                          IconButton(
                            onPressed: _removeImage,
                            icon: Icon(
                              Icons.delete,
                              color: theme.colorScheme.error,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Text(
                          'No image selected',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _takePicture,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateArticle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Update Article'),
            ),
          ],
        ),
      ),
    );
  }
}
