import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_form_container.dart';
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

  final OnboardingController _onboardingController = OnboardingController();

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
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
        const SnackBar(content: Text('Profile completed successfully!')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _onboardingController.errorMessage ??
                'Failed to complete onboarding. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: ResponsiveFormContainer(
        maxWidth: 600,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to OneCamp! 🎓',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete your student profile to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Academic Information Section Card
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
                          prefixIcon: Icon(Icons.account_balance_outlined),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Personal Information Section Card
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
                            'Personal Details & Interests',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                        ),
                        validator: (value) {
                          if (value == null ||
                              _parseCommaSeparated(value).isEmpty) {
                            return 'Please enter at least one interest (separated by commas).';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Complete Profile',
                onPressed: _isSaving ? null : _submitOnboarding,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
