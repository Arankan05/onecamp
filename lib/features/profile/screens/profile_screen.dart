import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
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
            icon: const Icon(Icons.edit_outlined),
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
            icon: const Icon(Icons.logout_rounded),
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
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveFormContainer(
      maxWidth: 580,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // 1. Header Card (Profile Picture, Name, Email, Role)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppTheme.lavenderGradient,
              ),
              child: Column(
                children: [
                  // Centered Profile Picture with Purple Border Ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.secondaryColor,
                      backgroundImage: profile.profileImageUrl != null &&
                              profile.profileImageUrl!.isNotEmpty
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                      child: profile.profileImageUrl == null ||
                              profile.profileImageUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 44,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name with Verified Checkmark Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // User Email
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // User Role Badge
                  Chip(
                    avatar: Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      profile.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. "About You" White Rounded Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'About You',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PROFILE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bio Box
                  _buildInfoBox(
                    label: 'BIO',
                    value: profile.bio?.isNotEmpty == true
                        ? profile.bio!
                        : 'Not added',
                    icon: Icons.notes_rounded,
                    theme: theme,
                  ),

                  const SizedBox(height: 8),

                  // Skills Section
                  Text(
                    'SKILLS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (profile.skills.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.skills
                          .map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF231F4C)
                            : const Color(0xFFF8F6FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : const Color(0xFFE8E3FA),
                        ),
                      ),
                      child: Text(
                        'Not added',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Interests Section
                  Text(
                    'INTERESTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (profile.interests.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map(
                            (interest) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3730A3)
                                    : AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF4C1D95)
                                      : const Color(0xFFDDD6FE),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF231F4C)
                            : const Color(0xFFF8F6FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : const Color(0xFFE8E3FA),
                        ),
                      ),
                      child: Text(
                        'Not added',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. "Academic Information" White Rounded Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // University Box
                  _buildInfoBox(
                    label: 'UNIVERSITY',
                    value: profile.university?.isNotEmpty == true
                        ? profile.university!
                        : 'Not added',
                    icon: Icons.account_balance_outlined,
                    theme: theme,
                  ),

                  // Faculty Box
                  _buildInfoBox(
                    label: 'FACULTY',
                    value: profile.faculty?.isNotEmpty == true
                        ? profile.faculty!
                        : 'Not added',
                    icon: Icons.domain_outlined,
                    theme: theme,
                  ),

                  // Degree / Programme Box
                  _buildInfoBox(
                    label: 'DEGREE / PROGRAMME',
                    value: profile.degree?.isNotEmpty == true
                        ? profile.degree!
                        : 'Not added',
                    icon: Icons.school_outlined,
                    theme: theme,
                  ),

                  // Department Box
                  _buildInfoBox(
                    label: 'DEPARTMENT',
                    value: profile.department?.isNotEmpty == true
                        ? profile.department!
                        : 'Not added',
                    icon: Icons.business_outlined,
                    theme: theme,
                  ),

                  // Academic Year Box
                  _buildInfoBox(
                    label: 'ACADEMIC YEAR',
                    value: profile.academicYear != null
                        ? 'Year ${profile.academicYear}'
                        : 'Not added',
                    icon: Icons.calendar_today_outlined,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds an individual, light-coloured rounded information box
  /// with a purple icon, small grey uppercase label, and saved value.
  Widget _buildInfoBox({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    final boxBgColor = isDark
        ? const Color(0xFF231F4C)
        : const Color(0xFFF8F6FE);

    final borderColor = isDark
        ? const Color(0xFF3730A3)
        : const Color(0xFFE8E3FA);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x803730A3)
                  : AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
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
