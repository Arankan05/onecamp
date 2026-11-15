
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

    if (shouldLogout == true) {
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

          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            profile.email,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          _buildInfoTile(
            icon: Icons.badge_outlined,
            title: 'User Role',
            value: profile.role,
          ),

          _buildInfoTile(
            icon: Icons.school_outlined,
            title: 'Department',
            value: profile.department ?? 'Not added',
          ),

          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            title: 'Academic Year',
            value: profile.academicYear?.toString() ??
                'Not added',
          ),

          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Bio',
            value: profile.bio ?? 'Not added',
          ),
        ],
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
