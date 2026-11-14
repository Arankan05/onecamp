import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/chat_repository.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import '../widgets/chat_avatar.dart';
import '../../../routes/app_routes.dart';

class CreateGroupScreen extends StatefulWidget {
  final ChatRepository? chatRepository;

  const CreateGroupScreen({
    super.key,
    this.chatRepository,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late final ChatRepository _chatRepository;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _chatRepository = widget.chatRepository ?? ChatRepository();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGroup() async {
    final currentUid = _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    final groupName = _groupNameController.text.trim();

    if (currentUid == null || currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create a group.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one other student for the group.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final participantIds = [currentUid, ..._selectedUserIds];
      final chatId = await _chatRepository.createGroupChat(
        currentUserId: currentUid,
        participantIds: participantIds,
        groupName: groupName,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId,
            'title': groupName,
            'isGroup': true,
            'participantIds': participantIds,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
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
        title: const Text('Create Group Chat', style: ChatTextStyles.appBarTitle),
        backgroundColor: ChatColors.cardBackground,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _handleCreateGroup,
            child: const Text(
              'Create',
              style: TextStyle(
                color: ChatColors.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Group Name Header Section
              Container(
                color: ChatColors.cardBackground,
                padding: const EdgeInsets.all(ChatDimensions.paddingL),
                child: Column(
                  children: [
                    TextField(
                      controller: _groupNameController,
                      decoration: ChatDecorations.inputDecoration('Enter group name...').copyWith(
                        prefixIcon: const Icon(Icons.group_outlined, color: ChatColors.primaryPurple),
                      ),
                    ),
                    const SizedBox(height: ChatDimensions.paddingM),
                    TextField(
                      controller: _searchController,
                      decoration: ChatDecorations.inputDecoration('Search members...').copyWith(
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
                  ],
                ),
              ),

              // Selected Members Chips Header
              if (_selectedUserIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatDimensions.paddingL,
                    vertical: ChatDimensions.paddingS,
                  ),
                  color: ChatColors.lightLavender,
                  width: double.infinity,
                  child: Text(
                    'Selected Members: ${_selectedUserIds.length}',
                    style: const TextStyle(
                      color: ChatColors.primaryDarkPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                ),

              // Student List with Selection Checkboxes
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
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
                            'Error loading members: ${snapshot.error}',
                            style: ChatTextStyles.chatTileSubtitle,
                          ),
                        ),
                      );
                    }

                    final users = snapshot.data ?? [];
                    final filteredUsers = users.where((u) {
                      if (_searchQuery.isEmpty) return true;
                      final name = (u['name'] as String? ?? u['displayName'] as String? ?? '').toLowerCase();
                      final email = (u['email'] as String? ?? '').toLowerCase();
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No students available.'
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
                        final uid = user['uid'] as String? ?? '';
                        final name = user['name'] as String? ??
                            user['displayName'] as String? ??
                            user['email'] as String? ??
                            'Student';
                        final email = user['email'] as String? ?? '';
                        final photoUrl = user['photoUrl'] as String? ?? user['avatarUrl'] as String?;
                        final isSelected = _selectedUserIds.contains(uid);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: ChatDimensions.paddingL,
                            vertical: ChatDimensions.paddingXS,
                          ),
                          decoration: ChatDecorations.cardDecoration,
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: ChatColors.primaryPurple,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedUserIds.add(uid);
                                } else {
                                  _selectedUserIds.remove(uid);
                                }
                              });
                            },
                            secondary: ChatAvatar(
                              name: name,
                              imageUrl: photoUrl,
                              size: ChatDimensions.avatarMedium,
                            ),
                            title: Text(name, style: ChatTextStyles.chatTileTitle),
                            subtitle: Text(
                              email,
                              style: ChatTextStyles.chatTileSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          if (_isCreating)
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
