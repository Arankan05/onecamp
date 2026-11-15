
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
  final _universityController = TextEditingController();
  final _facultyController = TextEditingController();
  final _degreeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();

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
      _universityController.text = profile.university ?? '';
      _facultyController.text = profile.faculty ?? '';
      _degreeController.text = profile.degree ?? '';
      _departmentController.text = profile.department ?? '';
      _academicYear = profile.academicYear;
      _profileImageUrl = profile.profileImageUrl;
      _skillsController.text = profile.skills.join(', ');
      _interestsController.text = profile.interests.join(', ');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select image: $error'),
        ),
      );
    }
  }

  List<String> _parseList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

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

      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadProfileImage(
          _selectedImage!,
        );
      }

      final success = await _profileController.updateProfile(
        uid: user.uid,
        name: _nameController.text,
        bio: _bioController.text,
        university: _universityController.text,
        faculty: _facultyController.text,
        degree: _degreeController.text,
        department: _departmentController.text,
        academicYear: _academicYear,
        skills: _parseList(_skillsController.text),
        interests: _parseList(_interestsController.text),
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
    _universityController.dispose();
    _facultyController.dispose();
    _degreeController.dispose();
    _departmentController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
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
                      onPressed:
                      _isSaving ? null : _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Choose Profile Picture',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              const Text(
                'Academic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _universityController,
                label: 'University',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _facultyController,
                label: 'Faculty',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _degreeController,
                label: 'Degree / Programme',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _departmentController,
                label: 'Department',
              ),

              const SizedBox(height: 16),

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
                onChanged: _isSaving
                    ? null
                    : (value) {
                  setState(() {
                    _academicYear = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Skills and Interests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _skillsController,
                label: 'Skills',
                maxLines: 2,
                hint: 'Example: Flutter, Java, Python',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _interestsController,
                label: 'Interests',
                maxLines: 2,
                hint: 'Example: AI, Robotics, Sports',
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed:
                _isSaving ? null : _saveProfile,
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
