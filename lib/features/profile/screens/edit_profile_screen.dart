import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../../../core/widgets/responsive_form_container.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
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
          backgroundColor: Theme.of(context).colorScheme.error,
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in again.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _profileImageUrl;

      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadProfileImage(_selectedImage!);
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
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _profileController.errorMessage ?? 'Failed to update profile.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload or update failed: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ImageProvider? imageProvider;

    if (_selectedImageBytes != null) {
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FD),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFF4F0FD),
        elevation: 0,
        leading: const OneCampBackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveFormContainer(
              maxWidth: 640,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image Picker Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? Icon(
                                          Icons.person,
                                          size: 56,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
                                ),
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.colorScheme.primary,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isSaving ? null : _pickImage,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isSaving ? null : _pickImage,
                            child: const Text('Choose Profile Picture'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Personal Information',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bioController,
                              enabled: !_isSaving,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                prefixIcon: Icon(Icons.info_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Academic Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Academic Information',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _universityController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'University',
                                prefixIcon: Icon(
                                  Icons.account_balance_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _facultyController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Faculty',
                                prefixIcon: Icon(Icons.domain_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _degreeController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Degree / Programme',
                                prefixIcon: Icon(Icons.history_edu_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _departmentController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _academicYear,
                              decoration: const InputDecoration(
                                labelText: 'Academic Year',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Skills and Interests Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Skills and Interests',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _skillsController,
                              enabled: !_isSaving,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Skills',
                                hintText: 'Example: Flutter, Java, Python',
                                prefixIcon: Icon(Icons.code_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _interestsController,
                              enabled: !_isSaving,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Interests',
                                hintText: 'Example: AI, Robotics, Sports',
                                prefixIcon: Icon(Icons.interests_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _isSaving ? null : _saveProfile,
                      isLoading: _isSaving,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
