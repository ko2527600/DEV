import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:developer' as developer;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      developer.log('Error picking image from camera: $e', name: 'ImageService');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      developer.log('Error picking image from gallery: $e', name: 'ImageService');
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      final List<File> files = [];
      for (int i = 0; i < images.length && i < maxImages; i++) {
        files.add(File(images[i].path));
      }
      
      return files;
    } catch (e) {
      developer.log('Error picking multiple images: $e', name: 'ImageService');
      return [];
    }
  }

  // Cross-platform: pick multiple images as bytes (web-safe)
  Future<List<Uint8List>> pickMultipleImageBytesFromGallery({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      final List<Uint8List> results = [];
      for (int i = 0; i < images.length && i < maxImages; i++) {
        final bytes = await images[i].readAsBytes();
        results.add(bytes);
      }
      return results;
    } catch (e) {
      developer.log('Error picking multiple images (bytes): $e', name: 'ImageService');
      return [];
    }
  }

  // Cross-platform: pick single image as bytes from camera
  Future<Uint8List?> pickImageBytesFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null) return null;
      return await image.readAsBytes();
    } catch (e) {
      developer.log('Error picking image from camera (bytes): $e', name: 'ImageService');
      return null;
    }
  }

  // Compress image
  Future<File?> compressImage(File imageFile) async {
    try {
      final String targetPath = '${imageFile.path}_compressed.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );
      
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      developer.log('Error compressing image: $e', name: 'ImageService');
      return null;
    }
  }

  // Compress multiple images
  Future<List<File>> compressImages(List<File> imageFiles) async {
    try {
      final List<File> compressedFiles = [];
      
      for (final imageFile in imageFiles) {
        final compressed = await compressImage(imageFile);
        if (compressed != null) {
          compressedFiles.add(compressed);
        }
      }
      
      return compressedFiles;
    } catch (e) {
      developer.log('Error compressing images: $e', name: 'ImageService');
      return [];
    }
  }

  // Get image file size in MB
  double getImageFileSize(File imageFile) {
    try {
      final bytes = imageFile.lengthSync();
      return bytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      developer.log('Error getting file size: $e', name: 'ImageService');
      return 0.0;
    }
  }

  // Check if image file size is within limit
  bool isImageSizeValid(File imageFile, {double maxSizeMB = 5.0}) {
    final size = getImageFileSize(imageFile);
    return size <= maxSizeMB;
  }

  // Validate image dimensions
  bool isImageDimensionsValid(File imageFile, {
    int minWidth = 100,
    int minHeight = 100,
    int maxWidth = 4096,
    int maxHeight = 4096,
  }) {
    try {
      // This is a basic check - in a real app you might want to decode the image
      // to get actual dimensions, but that's expensive
      return true; // Placeholder for now
    } catch (e) {
      developer.log('Error validating image dimensions: $e', name: 'ImageService');
      return false;
    }
  }

  // Get image info
  Map<String, dynamic> getImageInfo(File imageFile) {
    try {
      final size = getImageFileSize(imageFile);
      final path = imageFile.path;
      final name = path.split('/').last;
      
      return {
        'name': name,
        'path': path,
        'sizeMB': size,
        'sizeValid': isImageSizeValid(imageFile),
        'dimensionsValid': isImageDimensionsValid(imageFile),
      };
    } catch (e) {
      developer.log('Error getting image info: $e', name: 'ImageService');
      return {};
    }
  }

  // Clean up temporary files
  Future<void> cleanupTempFiles(List<File> tempFiles) async {
    try {
      for (final file in tempFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      developer.log('Error cleaning up temp files: $e', name: 'ImageService');
    }
  }

  // Convert file to bytes
  Future<Uint8List?> fileToBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      developer.log('Error converting file to bytes: $e', name: 'ImageService');
      return null;
    }
  }

  // Save bytes to file
  Future<File?> saveBytesToFile(Uint8List bytes, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      developer.log('Error saving bytes to file: $e', name: 'ImageService');
      return null;
    }
  }

  // Generate thumbnail
  Future<File?> generateThumbnail(File imageFile, {
    int width = 200,
    int height = 200,
    int quality = 70,
  }) async {
    try {
      final String targetPath = '${imageFile.path}_thumb.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: width,
        minHeight: height,
      );
      
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      developer.log('Error generating thumbnail: $e', name: 'ImageService');
      return null;
    }
  }
}
