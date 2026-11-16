
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profileController;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    _profileController = ProfileController();

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      _profileController.loadProfile(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  // Show logout confirmation dialog.
  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await _logout();
    }
  }

  // Sign out the current Firebase user.
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view your profile.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: _isLoggingOut
                ? null
                : () async {
              final result = await Navigator.pushNamed(
                context,
                '/edit-profile',
              );

              if (result == true && mounted) {
                _profileController.loadProfile(
                  currentUser.uid,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed:
            _isLoggingOut ? null : _confirmLogout,
          ),
        ],
      ),
      body: _isLoggingOut
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : AnimatedBuilder(
        animation: _profileController,
        builder: (context, child) {
          switch (_profileController.status) {
            case ProfileStatus.initial:
            case ProfileStatus.loading:
              return const Center(
                child: CircularProgressIndicator(),
              );

            case ProfileStatus.error:
              return Center(
                child: Text(
                  _profileController.errorMessage ??
                      'Something went wrong.',
                ),
              );

            case ProfileStatus.success:
              final UserProfile profile =
              _profileController.profile!;

              return _buildProfileContent(profile);
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Profile picture.
          CircleAvatar(
            radius: 55,
            backgroundImage:
            profile.profileImageUrl != null &&
                profile.profileImageUrl!.isNotEmpty
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child: profile.profileImageUrl == null ||
                profile.profileImageUrl!.isEmpty
                ? const Icon(
              Icons.person,
              size: 60,
            )
                : null,
          ),

          const SizedBox(height: 20),

          // User name.
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Email.
          Text(
            profile.email,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          // Personal information.
          _buildSectionTitle('Personal Information'),

          _buildInfoTile(
            icon: Icons.badge_outlined,
            title: 'User Role',
            value: profile.role,
          ),

          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Bio',
            value: profile.bio?.isNotEmpty == true
                ? profile.bio!
                : 'Not added',
          ),

          const SizedBox(height: 16),

          // Academic information.
          _buildSectionTitle('Academic Information'),

          _buildInfoTile(
            icon: Icons.account_balance_outlined,
            title: 'University',
            value: profile.university?.isNotEmpty == true
                ? profile.university!
                : 'Not added',
          ),

          _buildInfoTile(
            icon: Icons.school_outlined,
            title: 'Faculty',
            value: profile.faculty?.isNotEmpty == true
                ? profile.faculty!
                : 'Not added',
          ),

          _buildInfoTile(
            icon: Icons.menu_book_outlined,
            title: 'Degree / Programme',
            value: profile.degree?.isNotEmpty == true
                ? profile.degree!
                : 'Not added',
          ),

          _buildInfoTile(
            icon: Icons.business_outlined,
            title: 'Department',
            value: profile.department?.isNotEmpty == true
                ? profile.department!
                : 'Not added',
          ),

          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            title: 'Academic Year',
            value: profile.academicYear != null
                ? 'Year ${profile.academicYear}'
                : 'Not added',
          ),

          const SizedBox(height: 16),

          // Skills.
          _buildSectionTitle('Skills'),

          _buildInfoTile(
            icon: Icons.code,
            title: 'My Skills',
            value: profile.skills.isEmpty
                ? 'Not added'
                : profile.skills.join(', '),
          ),

          const SizedBox(height: 16),

          // Interests.
          _buildSectionTitle('Interests'),

          _buildInfoTile(
            icon: Icons.interests_outlined,
            title: 'My Interests',
            value: profile.interests.isEmpty
                ? 'Not added'
                : profile.interests.join(', '),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 12,
          top: 8,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
