import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _universityController = TextEditingController();
  final _facultyController = TextEditingController();
  final _degreeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();

  final OnboardingController _onboardingController =
      OnboardingController();

  int? _academicYear;
  bool _isSaving = false;

  @override
  void dispose() {
    _universityController.dispose();
    _facultyController.dispose();
    _degreeController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  List<String> _parseCommaSeparated(String text) {
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _submitOnboarding() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await _onboardingController.completeOnboarding(
      uid: user.uid,
      university: _universityController.text.trim(),
      faculty: _facultyController.text.trim(),
      degree: _degreeController.text.trim(),
      department: _departmentController.text.trim(),
      academicYear: _academicYear!,
      bio: _bioController.text.trim(),
      skills: _parseCommaSeparated(_skillsController.text),
      interests: _parseCommaSeparated(_interestsController.text),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully!'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _onboardingController.errorMessage ??
                'Failed to complete onboarding. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Onboarding'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _isSaving ? null : _logout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to OneCamp! 🎓',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please complete your student profile to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Academic Information Section
                const Text(
                  'Academic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _universityController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'University',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your university.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _facultyController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Faculty',
                    prefixIcon: Icon(Icons.domain_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your faculty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _degreeController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Degree / Programme',
                    prefixIcon: Icon(Icons.history_edu_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your degree or programme.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _departmentController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your department.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  initialValue: _academicYear,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
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
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your academic year.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  enabled: !_isSaving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us a bit about yourself...',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a bio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _skillsController,
                  enabled: !_isSaving,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    hintText: 'e.g., Flutter, Dart, Java, Python',
                    prefixIcon: Icon(Icons.code_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        _parseCommaSeparated(value).isEmpty) {
                      return 'Please enter at least one skill (separated by commas).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _interestsController,
                  enabled: !_isSaving,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Interests',
                    hintText: 'e.g., AI, Robotics, Music, Sports',
                    prefixIcon: Icon(Icons.interests_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        _parseCommaSeparated(value).isEmpty) {
                      return 'Please enter at least one interest (separated by commas).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSaving ? null : _submitOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
