
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();

  final ProfileController _profileController = ProfileController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _profileImageUrl;

  int? _academicYear;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Load the current user's profile from Firestore.
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await _profileController.loadProfile(user.uid);

    if (!mounted) return;

    final UserProfile? profile = _profileController.profile;

    if (profile != null) {
      _nameController.text = profile.name;
      _bioController.text = profile.bio ?? '';
      _departmentController.text = profile.department ?? '';
      _academicYear = profile.academicYear;
      _profileImageUrl = profile.profileImageUrl;
    }

    setState(() => _isLoading = false);
  }

  // Open the gallery and select a profile picture.
  Future<void> _pickImage() async {
    try {
      debugPrint('Opening image picker...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image == null) {
        debugPrint('No image selected.');
        return;
      }

      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });

      debugPrint('Image selected: ${image.name}');
    } catch (error) {
      debugPrint('Image picker error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select image: $error'),
        ),
      );
    }
  }

  // Upload the image and save profile details.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _profileImageUrl;

      // Upload a new image only if one was selected.
      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadProfileImage(
          _selectedImage!,
        );
      }

      final success = await _profileController.updateProfile(
        uid: user.uid,
        name: _nameController.text,
        bio: _bioController.text,
        department: _departmentController.text,
        academicYear: _academicYear,
        profileImageUrl: imageUrl,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _profileController.errorMessage ??
                  'Failed to update profile.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload or update failed: $error'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (_selectedImageBytes != null) {
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (_profileImageUrl != null &&
        _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile picture and image selection button.
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                        Icons.person,
                        size: 60,
                      )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Choose Profile Picture',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Full name.
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Bio.
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Department.
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Academic year.
              DropdownButtonFormField<int>(
                initialValue: _academicYear,
                decoration: const InputDecoration(
                  labelText: 'Academic Year',
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3, 4, 5]
                    .map(
                      (year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text('Year $year'),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _academicYear = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Save changes.
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
