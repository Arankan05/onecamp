import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/onecamp_back_button.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';
import '../services/cloudinary_service.dart';
import '../widgets/image_picker_preview.dart';

/// Form screen for creating or editing a marketplace listing.
class CreateEditItemScreen extends StatefulWidget {
  final bool isEditing;
  final MarketplaceItem? item;
  final MarketplaceRepository? repository;
  final CloudinaryService? cloudinaryService;

  const CreateEditItemScreen({
    super.key,
    this.isEditing = false,
    this.item,
    this.repository,
    this.cloudinaryService,
  });

  @override
  State<CreateEditItemScreen> createState() => _CreateEditItemScreenState();
}

class _CreateEditItemScreenState extends State<CreateEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final MarketplaceRepository _repository;
  late final CloudinaryService _cloudinaryService;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  late String _selectedCategory;
  late String _selectedCondition;

  final List<String> _retainedCloudinaryUrls = [];
  final List<XFile> _newImageFiles = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarketplaceRepository();
    _cloudinaryService = widget.cloudinaryService ?? CloudinaryService();

    final item = widget.item;

    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _priceController = TextEditingController(
      text: item != null
          ? item.price.toStringAsFixed(
              item.price.truncateToDouble() == item.price ? 0 : 2,
            )
          : '',
    );
    _locationController = TextEditingController(text: item?.location ?? '');

    final categories = AppConstants.marketplaceCategories
        .where((c) => c != 'All')
        .toList();
    _selectedCategory = (item != null && categories.contains(item.category))
        ? item.category
        : categories.first;

    _selectedCondition =
        (item != null && AppConstants.itemConditions.contains(item.condition))
        ? item.condition
        : AppConstants.itemConditions.first;

    if (item != null) {
      _retainedCloudinaryUrls.addAll(item.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  int get _totalImageCount =>
      _retainedCloudinaryUrls.length + _newImageFiles.length;

  Future<void> _pickImages() async {
    if (_totalImageCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed per listing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == ImageSource.gallery) {
      final selectedList = await _picker.pickMultiImage();
      if (selectedList.isNotEmpty) {
        final availableSlots = 5 - _totalImageCount;
        final allowedList = selectedList.take(availableSlots).toList();
        setState(() {
          _newImageFiles.addAll(allowedList);
        });
      }
    } else {
      final captured = await _picker.pickImage(source: ImageSource.camera);
      if (captured != null && _totalImageCount < 5) {
        setState(() {
          _newImageFiles.add(captured);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign-in is required to save listings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload ONLY new local image files to Cloudinary
      final List<String> newlyUploadedUrls = [];
      if (_newImageFiles.isNotEmpty) {
        final uploaded = await _cloudinaryService.uploadMultipleXFiles(
          _newImageFiles,
        );
        newlyUploadedUrls.addAll(uploaded);
      }

      // 2. Combine retained existing URLs + newly uploaded Cloudinary URLs
      final List<String> finalImageUrls = [
        ..._retainedCloudinaryUrls,
        ...newlyUploadedUrls,
      ];

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final location = _locationController.text.trim();

      final keywords = MarketplaceItem.generateKeywords(
        title,
        description,
        _selectedCategory,
      );

      if (widget.isEditing && widget.item != null) {
        // Edit Mode
        final updatedItem = widget.item!.copyWith(
          title: title,
          description: description,
          price: price,
          category: _selectedCategory,
          condition: _selectedCondition,
          imageUrls: finalImageUrls,
          location: location.isNotEmpty ? location : null,
          searchKeywords: keywords,
        );

        await _repository.updateItem(updatedItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create Mode
        final newItem = MarketplaceItem(
          id: '',
          title: title,
          description: description,
          price: price,
          category: _selectedCategory,
          condition: _selectedCondition,
          imageUrls: finalImageUrls,
          sellerId: currentUser.uid,
          sellerName:
              currentUser.displayName ??
              currentUser.email?.split('@').first ??
              'Campus Seller',
          sellerEmail: currentUser.email ?? '',
          sellerPhotoUrl: currentUser.photoURL,
          status: AppConstants.statusAvailable,
          location: location.isNotEmpty ? location : null,
          searchKeywords: keywords,
        );

        await _repository.createItem(newItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing posted successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save listing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.marketplaceCategories
        .where((c) => c != 'All')
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Listing' : 'Post New Listing'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading images & saving listing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker & Preview Section
                    ImagePickerPreview(
                      retainedImageUrls: _retainedCloudinaryUrls,
                      newImageFiles: _newImageFiles,
                      onPickImagesPressed: _pickImages,
                      onRemoveRetainedUrl: (index) {
                        setState(() => _retainedCloudinaryUrls.removeAt(index));
                      },
                      onRemoveNewFile: (index) {
                        setState(() => _newImageFiles.removeAt(index));
                      },
                    ),

                    const SizedBox(height: 24),

                    // Item Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Item Title *',
                        hintText: 'e.g. Engineering Calculus Textbook',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title.';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Price Input
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price (\$) *',
                        hintText: 'e.g. 25 (Enter 0 for Free)',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price.';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null) {
                          return 'Please enter a valid numeric price.';
                        }
                        if (parsed < 0) {
                          return 'Price cannot be negative.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Condition Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condition *',
                      ),
                      items: AppConstants.itemConditions
                          .map(
                            (cond) => DropdownMenuItem(
                              value: cond,
                              child: Text(cond),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCondition = val);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description Input
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Provide details about condition, edition, usage, etc.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Location Input
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Campus Location (Optional)',
                        hintText: 'e.g. Main Library / Student Union',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: Text(
                          widget.isEditing ? 'Save Changes' : 'Post Listing',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
