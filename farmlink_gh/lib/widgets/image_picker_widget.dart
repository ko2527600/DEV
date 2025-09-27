import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants/app_constants.dart';

class ImagePickerWidget extends StatefulWidget {
  final List<File> selectedImages;
  final Function(List<File>) onImagesChanged;
  final int maxImages;
  final bool allowMultiple;

  const ImagePickerWidget({
    Key? key,
    required this.selectedImages,
    required this.onImagesChanged,
    this.maxImages = 5,
    this.allowMultiple = true,
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: AppConstants.maxImageWidth,
        maxHeight: AppConstants.maxImageHeight,
        imageQuality: AppConstants.imageQuality,
      );
      
      if (image != null) {
        _addImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      if (widget.allowMultiple) {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: AppConstants.maxImageWidth,
          maxHeight: AppConstants.maxImageHeight,
          imageQuality: AppConstants.imageQuality,
        );
        
        for (XFile image in images) {
          if (widget.selectedImages.length < widget.maxImages) {
            _addImage(File(image.path));
          } else {
            break;
          }
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: AppConstants.maxImageWidth,
          maxHeight: AppConstants.maxImageHeight,
          imageQuality: AppConstants.imageQuality,
        );
        
        if (image != null) {
          _addImage(File(image.path));
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _addImage(File image) {
    if (widget.selectedImages.length < widget.maxImages) {
      setState(() {
        widget.selectedImages.add(image);
      });
      widget.onImagesChanged(widget.selectedImages);
    } else {
      _showErrorSnackBar('Maximum ${widget.maxImages} images allowed');
    }
  }

  void _removeImage(int index) {
    setState(() {
      widget.selectedImages.removeAt(index);
    });
    widget.onImagesChanged(widget.selectedImages);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Images',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        
        // Image picker buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSmall),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(widget.allowMultiple ? 'Gallery' : 'Select'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMedium),
        
        // Selected images grid
        if (widget.selectedImages.isNotEmpty) ...[
          Text(
            'Selected Images (${widget.selectedImages.length}/${widget.maxImages})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppConstants.spacingSmall,
              mainAxisSpacing: AppConstants.spacingSmall,
              childAspectRatio: 1,
            ),
            itemCount: widget.selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    child: Image.file(
                      widget.selectedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        
        // Helper text
        if (widget.selectedImages.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMedium),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: Text(
                    'No images selected. Add up to ${widget.maxImages} product images.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
