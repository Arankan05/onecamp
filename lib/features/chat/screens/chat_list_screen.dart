import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/presence_service.dart';
import '../../profile/screens/other_user_profile_screen.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/chat_tile.dart';
import '../../../routes/app_routes.dart';

class ChatListScreen extends StatefulWidget {
  final ChatRepository? chatRepository;

  const ChatListScreen({super.key, this.chatRepository});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatRepository _chatRepository;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Direct', 'Groups', 'Clubs'

  final Map<String, String> _userNamesCache = {};
  final Map<String, String?> _userAvatarsCache = {};

  @override
  void initState() {
    super.initState();
    _chatRepository = widget.chatRepository ?? ChatRepository();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUserProfile(String userId) async {
    if (_userNamesCache.containsKey(userId)) return;
    final profile = await _chatRepository.getUserProfile(userId);
    if (profile != null && mounted) {
      setState(() {
        _userNamesCache[userId] =
            profile['name'] as String? ??
            profile['displayName'] as String? ??
            profile['email'] as String? ??
            'User';
        _userAvatarsCache[userId] =
            profile['profileImageUrl'] as String? ??
            profile['photoUrl'] as String? ??
            profile['avatarUrl'] as String?;
      });
    }
  }

  Widget _buildFilterPill(String label) {
    final bool isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: isActive ? ChatColors.pillActive : ChatColors.pillInactive,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            if (isActive)
              const BoxShadow(
                color: Color(0x4D7B38E0),
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : ChatColors.textPrimary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      return Scaffold(
        backgroundColor: ChatColors.pageBackground,
        appBar: AppBar(
          title: const Text('Messages', style: ChatTextStyles.appBarTitle),
          backgroundColor: ChatColors.cardBackground,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: ChatColors.textLight),
              SizedBox(height: 16),
              Text(
                'Please sign in to view your messages.',
                style: ChatTextStyles.chatTileSubtitle,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ChatColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatDimensions.paddingL,
                vertical: ChatDimensions.paddingS,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: ChatColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: ChatDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Messages',
                          style: ChatTextStyles.headerTitle,
                        ),
                        StreamBuilder<Set<String>>(
                          stream: PresenceService().getOnlineUserUidsStream(),
                          builder: (context, snapshot) {
                            final onlineUids = snapshot.data ?? {};
                            final count = onlineUids
                                .where((id) => id != currentUid)
                                .length;
                            return Text(
                              '$count ${count == 1 ? 'campus friend' : 'campus friends'} online',
                              style: ChatTextStyles.appBarSubtitle,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: ChatColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.newChat),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatDimensions.paddingL,
                vertical: ChatDimensions.paddingS,
              ),
              child: TextField(
                controller: _searchController,
                decoration:
                    ChatDecorations.inputDecoration(
                      'Search conversations or students...',
                    ).copyWith(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: ChatColors.primaryPurple,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: ChatColors.cardBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: ChatColors.primaryPurple,
                          size: 18,
                        ),
                      ),
                    ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),

            // Campus Active Section (Horizontal Avatar Row)
            Padding(
              padding: const EdgeInsets.only(
                left: ChatDimensions.paddingL,
                right: ChatDimensions.paddingL,
                top: ChatDimensions.paddingS,
                bottom: ChatDimensions.paddingXS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Campus active',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: ChatColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ChatColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      StreamBuilder<Set<String>>(
                        stream: PresenceService().getOnlineUserUidsStream(),
                        builder: (context, snapshot) {
                          final onlineUids = snapshot.data ?? {};
                          final onlineCount = onlineUids
                              .where((id) => id != currentUid)
                              .length;
                          return Text(
                            '$onlineCount online',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: ChatColors.onlineGreen,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Online Active Users List
            SizedBox(
              height: 80,
              child: StreamBuilder<Set<String>>(
                stream: PresenceService().getOnlineUserUidsStream(),
                builder: (context, onlineSnapshot) {
                  final onlineUids = onlineSnapshot.data ?? {};

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatRepository.getUsersStream(),
                    builder: (context, usersSnapshot) {
                      final allUsers = usersSnapshot.data ?? [];
                      final activeUsers = allUsers.where((u) {
                        final uid = u['uid'] as String?;
                        return uid != null &&
                            uid != currentUid &&
                            onlineUids.contains(uid);
                      }).toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ChatDimensions.paddingL,
                        ),
                        itemCount: activeUsers.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              margin: const EdgeInsets.only(right: 14.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: ChatColors.primaryPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Radar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ChatColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final user = activeUsers[index - 1];
                          final name =
                              user['name'] as String? ??
                              user['displayName'] as String? ??
                              'Student';
                          final uid = user['uid'] as String?;
                          final avatarUrl =
                              user['profileImageUrl'] as String? ??
                              user['photoUrl'] as String? ??
                              user['avatarUrl'] as String?;

                          return GestureDetector(
                            onTap: () {
                              if (uid != null && uid.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OtherUserProfileScreen(userId: uid),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 14.0),
                              child: Column(
                                children: [
                                  ChatAvatar(
                                    name: name,
                                    imageUrl: avatarUrl,
                                    userId: uid,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 52,
                                    child: Text(
                                      name.split(' ')[0],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: ChatColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Filter Pills Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatDimensions.paddingL,
                vertical: ChatDimensions.paddingS,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('All'),
                    _buildFilterPill('Direct'),
                    _buildFilterPill('Groups'),
                    _buildFilterPill('Clubs'),
                  ],
                ),
              ),
            ),

            // Chat Cards Stream List
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: _chatRepository.getChatsStream(currentUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ChatColors.primaryPurple,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ChatDimensions.paddingXL),
                        child: Text(
                          'Error loading chats: ${snapshot.error}',
                          style: ChatTextStyles.chatTileSubtitle,
                        ),
                      ),
                    );
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.forum_outlined,
                            size: 56,
                            color: ChatColors.primaryPurple,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No conversations yet',
                            style: ChatTextStyles.chatTileTitle,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap New chat below to message a student!',
                            style: ChatTextStyles.chatTileSubtitle,
                          ),
                        ],
                      ),
                    );
                  }

                  // Apply Type Filter
                  final typeFiltered = chats.where((c) {
                    if (_selectedFilter == 'Direct') return !c.isGroup;
                    if (_selectedFilter == 'Groups' ||
                        _selectedFilter == 'Clubs')
                      return c.isGroup;
                    return true;
                  }).toList();

                  // Apply Search Filter
                  final filteredChats = typeFiltered.where((chat) {
                    if (_searchQuery.isEmpty) return true;
                    final lastMsg = (chat.lastMessage ?? '').toLowerCase();
                    if (chat.isGroup) {
                      final groupName = (chat.groupName ?? '').toLowerCase();
                      return groupName.contains(_searchQuery) ||
                          lastMsg.contains(_searchQuery);
                    } else {
                      final otherId = chat.participantIds.firstWhere(
                        (id) => id != currentUid,
                        orElse: () => '',
                      );
                      final otherName = (_userNamesCache[otherId] ?? '')
                          .toLowerCase();
                      return otherName.contains(_searchQuery) ||
                          lastMsg.contains(_searchQuery);
                    }
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: ChatDimensions.paddingXS,
                      bottom: 80,
                    ),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];

                      if (chat.isGroup) {
                        return ChatTile(
                          chat: chat,
                          title: chat.groupName ?? 'Group Chat',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.chatRoom,
                              arguments: {
                                'chatId': chat.chatId,
                                'title': chat.groupName ?? 'Group Chat',
                                'isGroup': true,
                                'participantIds': chat.participantIds,
                              },
                            );
                          },
                        );
                      } else {
                        final otherId = chat.participantIds.firstWhere(
                          (id) => id != currentUid,
                          orElse: () => '',
                        );

                        if (otherId.isNotEmpty &&
                            !_userNamesCache.containsKey(otherId)) {
                          _loadOtherUserProfile(otherId);
                        }

                        final title = _userNamesCache[otherId] ?? 'Student';
                        final avatarUrl = _userAvatarsCache[otherId];

                        return ChatTile(
                          chat: chat,
                          title: title,
                          avatarUrl: avatarUrl,
                          otherUserId: otherId,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.chatRoom,
                              arguments: {
                                'chatId': chat.chatId,
                                'title': title,
                                'isGroup': false,
                                'avatarUrl': avatarUrl,
                                'participantIds': chat.participantIds,
                                'otherUserId': otherId,
                              },
                            );
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Floating "New chat" Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: FloatingActionButton.extended(
          backgroundColor: ChatColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.edit_note, size: 22),
          label: const Text(
            'New chat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.newChat);
          },
        ),
      ),
    );
  }
}
