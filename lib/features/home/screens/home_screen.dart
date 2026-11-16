import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../communities/screens/create_community_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int index)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
  });

  User? _getCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _getCurrentUser();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'OneCamp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Push notifications are active for messages and WebRTC calls.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            _buildWelcomeCard(context, user, theme),
            const SizedBox(height: 20),

            // Quick Access Navigation Section
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickAccessSection(context),
            const SizedBox(height: 24),

            // Campus Overview & Activity Section
            const Text(
              'Campus Activity Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCampusOverviewCard(context),
            const SizedBox(height: 24),

            // Module Directory & Feature Roadmap Section
            const Text(
              'Campus Modules Directory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildModuleGrid(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to OneCamp! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your university hub for messaging, student communities, and campus life.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, User? user, ThemeData theme) {
    if (user == null) {
      return _buildDefaultWelcomeCard(context);
    }

    try {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String displayName = user.displayName ?? user.email?.split('@').first ?? 'Student';
          String role = 'Student';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              displayName = data['name'] as String? ?? displayName;
              role = (data['role'] as String? ?? 'student').toUpperCase();
            }
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  Colors.deepPurple.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Welcome back,\n$displayName! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connect with peers, collaborate in communities, and chat in real-time.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      return _buildDefaultWelcomeCard(context);
    }
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Communities',
            subtitle: 'Join student clubs & study groups',
            icon: Icons.groups_rounded,
            color: Colors.blue.shade700,
            onTap: () {
              if (onNavigateToTab != null) {
                onNavigateToTab!(1); // Index 1: Communities Tab
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Chat & Calls',
            subtitle: 'Direct messages & WebRTC calling',
            icon: Icons.forum_rounded,
            color: Colors.teal.shade700,
            onTap: () {
              if (onNavigateToTab != null) {
                onNavigateToTab!(2); // Index 2: Chat Tab
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampusOverviewCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryColor),
              ),
              title: const Text(
                'Campus Announcements',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Stay updated with university activities and events.'),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Want to start a new club or group?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateCommunityScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ModuleItem('Communities', 'Student clubs & groups', Icons.groups_rounded, Colors.blue, true, () {
        if (onNavigateToTab != null) onNavigateToTab!(1);
      }),
      _ModuleItem('Real-Time Chat', 'Messages & WebRTC calls', Icons.chat_bubble_rounded, Colors.green, true, () {
        if (onNavigateToTab != null) onNavigateToTab!(2);
      }),
      _ModuleItem('Student Profile', 'Academic bio & skills', Icons.person_rounded, Colors.purple, true, () {
        if (onNavigateToTab != null) onNavigateToTab!(3);
      }),
      _ModuleItem('Campus Feed', 'Social posts & news', Icons.dynamic_feed_rounded, Colors.orange, false, null),
      _ModuleItem('Marketplace', 'Buy & sell textbooks', Icons.storefront_rounded, Colors.teal, false, null),
      _ModuleItem('Events & Schedule', 'University calendar', Icons.event_rounded, Colors.red, false, null),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final item = modules[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: item.isAvailable ? item.onTap : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} is coming soon in an upcoming module update.'),
                  backgroundColor: Colors.indigo,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(item.icon, color: item.isAvailable ? item.color : Colors.grey, size: 26),
                      if (!item.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade800, width: 0.8),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: item.isAvailable ? null : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final VoidCallback? onTap;

  _ModuleItem(this.title, this.subtitle, this.icon, this.color, this.isAvailable, this.onTap);
}
