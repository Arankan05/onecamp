import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/follow_controller.dart';
import '../../profile/models/user_profile.dart';
import 'feed_test_login_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() =>
      _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FollowController _controller = FollowController();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view students.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const FeedTestLoginScreen(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [

// Following and Followers counts
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Following count
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _controller.getFollowingCount(currentUser.uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 30,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Following',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Followers count
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _controller.getFollowersCount(currentUser.uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.person_add_alt_1,
                                size: 30,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Followers',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),


          // Student list
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _controller.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final students = (snapshot.data ?? [])
                    .where(
                      (student) =>
                  student.uid != currentUser.uid,
                )
                    .toList();

                if (students.isEmpty) {
                  return const Center(
                    child: Text('No other students found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(student.name),
                        subtitle: Text(student.email),
                        trailing: StreamBuilder<bool>(
                          stream: _controller.isFollowing(
                            currentUserId: currentUser.uid,
                            targetUserId: student.uid,
                          ),
                          builder: (context, followSnapshot) {
                            final isFollowing =
                                followSnapshot.data ?? false;

                            return ElevatedButton(
                              onPressed: followSnapshot.hasError
                                  ? null
                                  : () async {
                                try {
                                  if (isFollowing) {
                                    await _controller.unfollowUser(
                                      currentUserId:
                                      currentUser.uid,
                                      targetUserId: student.uid,
                                    );
                                  } else {
                                    await _controller.followUser(
                                      currentUserId:
                                      currentUser.uid,
                                      targetUserId: student.uid,
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Following action failed: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                isFollowing
                                    ? 'Following'
                                    : 'Follow',
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
