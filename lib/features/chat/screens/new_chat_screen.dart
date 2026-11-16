import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/chat_repository.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import '../widgets/chat_avatar.dart';
import '../../../routes/app_routes.dart';

class NewChatScreen extends StatefulWidget {
  final ChatRepository? chatRepository;

  const NewChatScreen({
    super.key,
    this.chatRepository,
  });

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  late final ChatRepository _chatRepository;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreatingChat = false;

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

  Future<void> _startChatWithUser(Map<String, dynamic> targetUser) async {
    final currentUid = _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    final otherUid = targetUser['uid'] as String?;

    if (currentUid == null || otherUid == null || otherUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user selected.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isCreatingChat = true);

    try {
      final chatId = await _chatRepository.createDirectChat(
        currentUserId: currentUid,
        otherUserId: otherUid,
      );

      final title = targetUser['name'] as String? ??
          targetUser['displayName'] as String? ??
          targetUser['email'] as String? ??
          'Student';

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId,
            'title': title,
            'isGroup': false,
            'participantIds': [currentUid, otherUid],
            'otherUserId': otherUid,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatColors.pageBackground,
      appBar: AppBar(
        title: const Text('New Message', style: ChatTextStyles.appBarTitle),
        backgroundColor: ChatColors.cardBackground,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createGroup);
            },
            icon: const Icon(
              Icons.group_add_outlined,
              color: ChatColors.primaryPurple,
              size: 20,
            ),
            label: const Text(
              'Create Group',
              style: TextStyle(
                color: ChatColors.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Input
              Container(
                color: ChatColors.cardBackground,
                padding: const EdgeInsets.all(ChatDimensions.paddingL),
                child: TextField(
                  controller: _searchController,
                  decoration: ChatDecorations.inputDecoration('Search student name or faculty...').copyWith(
                    prefixIcon: const Icon(Icons.search, color: ChatColors.textLight),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: ChatColors.textLight),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                ),
              ),

              // Create Group Option Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatDimensions.paddingL,
                  vertical: ChatDimensions.paddingS,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.createGroup);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(ChatDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: ChatColors.cardBackground,
                      borderRadius: BorderRadius.circular(ChatDimensions.radiusM),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A4F1BAA),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0x157B38E0),
                          child: Icon(
                            Icons.groups_rounded,
                            color: ChatColors.primaryPurple,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 14),
                        Text(
                          'Create New Group Chat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ChatColors.primaryPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: ChatColors.textLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Student List with Blocked Filter Stream
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _chatRepository.getBlockedUserIdsStream(),
                  builder: (context, blockedSnapshot) {
                    final blockedUids = blockedSnapshot.data ?? [];

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _chatRepository.getUsersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: ChatColors.primaryPurple),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(ChatDimensions.paddingXL),
                              child: Text(
                                'Error loading students: ${snapshot.error}',
                                style: ChatTextStyles.chatTileSubtitle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final users = snapshot.data ?? [];

                        final filteredUsers = users.where((u) {
                          final uid = u['uid'] as String? ?? '';
                          if (blockedUids.contains(uid)) return false;

                          if (_searchQuery.isEmpty) return true;
                          final name = (u['name'] as String? ?? u['displayName'] as String? ?? '').toLowerCase();
                          final email = (u['email'] as String? ?? '').toLowerCase();
                          final faculty = (u['faculty'] as String? ?? u['department'] as String? ?? '').toLowerCase();

                          return name.contains(_searchQuery) ||
                              email.contains(_searchQuery) ||
                              faculty.contains(_searchQuery);
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No students found.'
                                  : 'No students matching "$_searchQuery".',
                              style: ChatTextStyles.chatTileSubtitle,
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: ChatDimensions.paddingS),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final name = user['name'] as String? ??
                                user['displayName'] as String? ??
                                user['email'] as String? ??
                                'Student';
                            final email = user['email'] as String? ?? '';
                            final faculty = user['faculty'] as String? ?? user['department'] as String? ?? '';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: ChatDimensions.paddingL,
                                vertical: ChatDimensions.paddingXS,
                              ),
                              decoration: ChatDecorations.cardDecoration,
                              child: ListTile(
                                onTap: _isCreatingChat ? null : () => _startChatWithUser(user),
                                leading: ChatAvatar(
                                  name: name,
                                  size: ChatDimensions.avatarMedium,
                                ),
                                title: Text(name, style: ChatTextStyles.chatTileTitle),
                                subtitle: Text(
                                  faculty.isNotEmpty ? '$faculty • $email' : email,
                                  style: ChatTextStyles.chatTileSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: ChatColors.primaryPurple,
                                  size: ChatDimensions.iconMedium,
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
            ],
          ),
          if (_isCreatingChat)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: ChatColors.primaryPurple),
              ),
            ),
        ],
      ),
    );
  }
}
