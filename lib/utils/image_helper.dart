import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  // Store file or web image data
  static File? pickedFile;
  static Uint8List? webImage;
  
  // Check if an image is selected (on any platform)
  static bool hasPickedImage() {
    if (kIsWeb) {
      return webImage != null;
    } else {
      return pickedFile != null;
    }
  }
  
  // Clear any selected image
  static void clearImage() {
    pickedFile = null;
    webImage = null;
  }
  
  // Pick image from gallery
  static Future<bool> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    
    if (pickedImage != null) {
      if (kIsWeb) {
        // For web, read the image as bytes
        webImage = await pickedImage.readAsBytes();
      } else {
        // For mobile, create a File object
        pickedFile = File(pickedImage.path);
      }
      return true;
    }
    return false;
  }
  
  // Take photo with camera
  static Future<bool> takePhoto() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    
    if (pickedImage != null) {
      if (kIsWeb) {
        // For web, read the image as bytes
        webImage = await pickedImage.readAsBytes();
      } else {
        // For mobile, create a File object
        pickedFile = File(pickedImage.path);
      }
      return true;
    }
    return false;
  }
  
  // Widget to display the picked image
  static Widget buildPickedImageWidget({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (kIsWeb && webImage != null) {
      return Image.memory(
        webImage!,
        height: height,
        width: width,
        fit: fit,
      );
    } else if (!kIsWeb && pickedFile != null) {
      return Image.file(
        pickedFile!,
        height: height,
        width: width,
        fit: fit,
      );
    } else {
      return const SizedBox.shrink(); // Empty widget if no image
    }
  }
}
