import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/responsive_form_container.dart';
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

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _profileController.loadProfile(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 40),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your profile.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                      _profileController.loadProfile(currentUser.uid);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _confirmLogout,
          ),
        ],
      ),
      body: _isLoggingOut
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _profileController,
              builder: (context, child) {
                switch (_profileController.status) {
                  case ProfileStatus.initial:
                  case ProfileStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case ProfileStatus.error:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _profileController.errorMessage ??
                              'Something went wrong.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );

                  case ProfileStatus.success:
                    final UserProfile profile = _profileController.profile!;
                    return _buildProfileContent(profile, theme);
                }
              },
            ),
    );
  }

  Widget _buildProfileContent(UserProfile profile, ThemeData theme) {
    return ResponsiveFormContainer(
      maxWidth: 640,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Avatar & Header
          Center(
            child: Column(
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
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: profile.profileImageUrl != null &&
                            profile.profileImageUrl!.isNotEmpty
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: profile.profileImageUrl == null ||
                            profile.profileImageUrl!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 56,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  profile.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 8),

                Chip(
                  avatar: const Icon(Icons.badge_outlined, size: 16),
                  label: Text(
                    profile.role.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Personal Information Card
          _buildCardSection(
            theme: theme,
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: 'Bio',
                value: profile.bio?.isNotEmpty == true
                    ? profile.bio!
                    : 'Not added',
              ),
            ],
          ),

          // Academic Information Card
          _buildCardSection(
            theme: theme,
            title: 'Academic Information',
            icon: Icons.school_outlined,
            children: [
              _buildInfoTile(
                icon: Icons.account_balance_outlined,
                title: 'University',
                value: profile.university?.isNotEmpty == true
                    ? profile.university!
                    : 'Not added',
              ),
              _buildInfoTile(
                icon: Icons.domain_outlined,
                title: 'Faculty',
                value: profile.faculty?.isNotEmpty == true
                    ? profile.faculty!
                    : 'Not added',
              ),
              _buildInfoTile(
                icon: Icons.history_edu_outlined,
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
            ],
          ),

          // Skills & Interests Card
          _buildCardSection(
            theme: theme,
            title: 'Skills & Interests',
            icon: Icons.star_outline,
            children: [
              const Text(
                'Skills',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              profile.skills.isEmpty
                  ? Text(
                      'Not added',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.skills
                          .map((skill) => Chip(
                                label: Text(skill),
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                              ))
                          .toList(),
                    ),
              const SizedBox(height: 16),
              const Text(
                'Interests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              profile.interests.isEmpty
                  ? Text(
                      'Not added',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map((interest) => Chip(
                                label: Text(interest),
                                backgroundColor: theme.colorScheme.secondary
                                    .withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ))
                          .toList(),
                    ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
