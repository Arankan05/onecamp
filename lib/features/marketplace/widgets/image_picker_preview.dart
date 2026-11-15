import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Hybrid image preview grid displaying retained Cloudinary URLs and newly picked local files.
class ImagePickerPreview extends StatelessWidget {
  final List<String> retainedImageUrls;
  final List<XFile> newImageFiles;
  final VoidCallback onPickImagesPressed;
  final ValueChanged<int> onRemoveRetainedUrl;
  final ValueChanged<int> onRemoveNewFile;
  final int maxImages;

  const ImagePickerPreview({
    super.key,
    required this.retainedImageUrls,
    required this.newImageFiles,
    required this.onPickImagesPressed,
    required this.onRemoveRetainedUrl,
    required this.onRemoveNewFile,
    this.maxImages = 5,
  });

  int get totalImages => retainedImageUrls.length + newImageFiles.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Listing Images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$totalImages/$maxImages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: totalImages >= maxImages
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add Image Button Card
              if (totalImages < maxImages)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: onPickImagesPressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Existing Retained Cloudinary URLs
              ...retainedImageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return _buildImageTile(
                  context,
                  imageWidget: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                  onDelete: () => onRemoveRetainedUrl(index),
                  badgeLabel: 'Existing',
                );
              }),

              // Newly Selected Local Image Files
              ...newImageFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final xFile = entry.value;
                return _buildImageTile(
                  context,
                  imageWidget: Image.file(File(xFile.path), fit: BoxFit.cover),
                  onDelete: () => onRemoveNewFile(index),
                  badgeLabel: 'New',
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(
    BuildContext context, {
    required Widget imageWidget,
    required VoidCallback onDelete,
    required String badgeLabel,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: imageWidget,
          ),

          // Delete (X) Button Badge
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),

          // New / Existing Badge Tag
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: badgeLabel == 'New'
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: badgeLabel == 'New'
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
