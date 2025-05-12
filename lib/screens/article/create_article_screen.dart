import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../../utils/image_helper.dart';

class CreateArticleScreen extends StatefulWidget {
  final bool startWithImage;
  
  const CreateArticleScreen({
    super.key,
    this.startWithImage = false,
  });

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _articleService = ArticleService();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // If startWithImage is true, automatically open image picker when screen loads
    if (widget.startWithImage) {
      // Use a post-frame callback to ensure the UI is built before showing the picker
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(); // Directly pick from gallery for better UX when starting with image
      });
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
        // Force refresh UI
        setState(() {});
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
        // Force refresh UI
        setState(() {});
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
    });
  }

  Future<void> _createArticle() async {
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

        final userData = await _authService.getUserData(user.uid);
        final authorName = userData?.name ?? user.email?.split('@')[0] ?? 'Anonymous';

        // Use different approach based on platform
        if (kIsWeb) {
          await _articleService.createArticleWeb(
            authorId: user.uid,
            authorName: authorName,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            webImageBytes: ImageHelper.webImage,
          );
        } else {
          await _articleService.createArticle(
            authorId: user.uid,
            authorName: authorName,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            imageFile: ImageHelper.pickedFile,
          );
        }

        if (!mounted) return;
        Navigator.pop(context);
      } catch (error) {
        setState(() {
          _errorMessage = 'Failed to create article: $error';
        });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Article'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  if (ImageHelper.hasPickedImage())
                    ElevatedButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (ImageHelper.hasPickedImage()) ...[                
                ImageHelper.buildPickedImageWidget(
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
              ],
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _createArticle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Publish Article'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
