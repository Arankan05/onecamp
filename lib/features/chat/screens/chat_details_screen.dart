import 'package:flutter/material.dart';

import '../../../core/widgets/onecamp_back_button.dart';
import '../repositories/chat_repository.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import '../widgets/chat_avatar.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final bool isGroup;
  final String? avatarUrl;
  final List<String> participantIds;
  final String? otherUserId;
  final ChatRepository? chatRepository;

  const ChatDetailsScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.isGroup = false,
    this.avatarUrl,
    this.participantIds = const [],
    this.otherUserId,
    this.chatRepository,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  late final ChatRepository _chatRepository;
  bool _isLoading = true;
  List<Map<String, dynamic>> _participantProfiles = [];

  @override
  void initState() {
    super.initState();
    _chatRepository = widget.chatRepository ?? ChatRepository();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final List<String> idsToFetch = widget.participantIds.isNotEmpty
        ? widget.participantIds
        : (widget.otherUserId != null
              ? <String>[widget.otherUserId!]
              : <String>[]);

    if (idsToFetch.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final profilesMap = await _chatRepository.getUsersProfiles(idsToFetch);
    if (mounted) {
      setState(() {
        _participantProfiles = profilesMap.entries.map((entry) {
          return {'uid': entry.key, ...entry.value};
        }).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatColors.pageBackground,
      appBar: AppBar(
        title: const Text('Chat Info', style: ChatTextStyles.appBarTitle),
        backgroundColor: ChatColors.cardBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ChatDimensions.paddingL),
        child: Column(
          children: [
            // Top Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ChatDimensions.paddingXL),
              decoration: ChatDecorations.cardDecoration,
              child: Column(
                children: [
                  ChatAvatar(
                    name: widget.title,
                    imageUrl: widget.avatarUrl,
                    size: ChatDimensions.avatarLarge,
                    isGroup: widget.isGroup,
                  ),
                  const SizedBox(height: ChatDimensions.paddingM),
                  Text(
                    widget.title,
                    style: ChatTextStyles.headerTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ChatDimensions.paddingM,
                      vertical: ChatDimensions.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: ChatColors.lightLavender,
                      borderRadius: BorderRadius.circular(
                        ChatDimensions.radiusXL,
                      ),
                    ),
                    child: Text(
                      widget.isGroup
                          ? 'Group Conversation'
                          : 'Direct Conversation',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: ChatColors.primaryDarkPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ChatDimensions.paddingL),

            // Details Header
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: ChatDimensions.paddingXS),
                child: Text(
                  widget.isGroup
                      ? 'Group Members (${_participantProfiles.length})'
                      : 'User Information',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: ChatColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ChatDimensions.paddingS),

            // Members / Profile List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(ChatDimensions.paddingXL),
                child: CircularProgressIndicator(
                  color: ChatColors.primaryPurple,
                ),
              )
            else if (_participantProfiles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(ChatDimensions.paddingL),
                decoration: ChatDecorations.cardDecoration,
                child: const Text(
                  'No profile information available.',
                  style: ChatTextStyles.chatTileSubtitle,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participantProfiles.length,
                itemBuilder: (context, index) {
                  final profile = _participantProfiles[index];
                  final name =
                      profile['name'] as String? ??
                      profile['displayName'] as String? ??
                      profile['email'] as String? ??
                      'Student';
                  final email = profile['email'] as String? ?? '';
                  final role = profile['role'] as String? ?? 'student';
                  final faculty =
                      profile['faculty'] as String? ??
                      profile['department'] as String? ??
                      '';
                  final photoUrl =
                      profile['photoUrl'] as String? ??
                      profile['avatarUrl'] as String?;

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: ChatDimensions.paddingS,
                    ),
                    decoration: ChatDecorations.cardDecoration,
                    child: ListTile(
                      leading: ChatAvatar(
                        name: name,
                        imageUrl: photoUrl,
                        size: ChatDimensions.avatarMedium,
                      ),
                      title: Text(name, style: ChatTextStyles.chatTileTitle),
                      subtitle: Text(
                        faculty.isNotEmpty ? '$faculty • $email' : email,
                        style: ChatTextStyles.chatTileSubtitle,
                      ),
                      trailing: (role == 'admin' || role == 'staff')
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ChatDimensions.paddingS,
                                vertical: ChatDimensions.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFC107),
                                borderRadius: BorderRadius.circular(
                                  ChatDimensions.radiusS,
                                ),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
