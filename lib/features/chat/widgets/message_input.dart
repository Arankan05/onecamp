import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../models/message_model.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(String imageUrl)? onSendImage;
  final MessageModel? replyingToMessage;
  final String? replyingToSenderName;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSendText,
    this.onSendImage,
    this.replyingToMessage,
    this.replyingToSenderName,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final CloudinaryUploadService _uploadService = CloudinaryUploadService();
  bool _isUploading = false;

  final List<String> _quickSuggestions = [
    'Sounds good!',
    'On my way',
    'Send location',
  ];

  void _handleSend([String? textToSend]) {
    if (_isUploading) return;
    final text = textToSend ?? _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      if (textToSend == null) {
        _controller.clear();
      }
      if (widget.onCancelReply != null) {
        widget.onCancelReply!();
      }
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChatDimensions.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ChatDimensions.paddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: ChatColors.primaryPurple),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndConfirmImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: ChatColors.primaryPurple),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndConfirmImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndConfirmImage(ImageSource source) async {
    try {
      final XFile? imageFile = await _uploadService.pickImage(source);
      if (imageFile == null || !mounted) return;

      _showImagePreviewDialog(imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog(XFile imageFile) {
    showDialog(
      context: context,
      barrierDismissible: !_isUploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: ChatColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChatDimensions.radiusM),
              ),
              title: const Text('Send Photo Preview'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ChatDimensions.radiusS),
                      child: Image.file(
                        File(imageFile.path),
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: ChatDimensions.paddingL),
                      const CircularProgressIndicator(color: ChatColors.primaryPurple),
                      const SizedBox(height: ChatDimensions.paddingS),
                      const Text(
                        'Uploading image...',
                        style: TextStyle(fontSize: 12, color: ChatColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!_isUploading) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(dialogContext);
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => _isUploading = true);
                      try {
                        final String secureUrl = await _uploadService.uploadImage(imageFile);
                        if (widget.onSendImage != null) {
                          await widget.onSendImage!(secureUrl);
                        }
                        navigator.pop();
                      } catch (e) {
                        setDialogState(() => _isUploading = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Upload failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatColors.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChatColors.pageBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Action Suggestions Chips matching Reference Screenshot
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: _quickSuggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () => _handleSend(suggestion),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: ChatColors.cardBackground,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A4F1BAA),
                          blurRadius: 4.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: ChatColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Reply Preview Banner
          if (widget.replyingToMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: ChatColors.cardBackground,
                borderRadius: BorderRadius.circular(12.0),
                border: const Border(
                  left: BorderSide(color: ChatColors.primaryPurple, width: 4.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${widget.replyingToSenderName ?? 'User'}',
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: ChatColors.primaryPurple,
                          ),
                        ),
                        Text(
                          widget.replyingToMessage!.text.isNotEmpty
                              ? widget.replyingToMessage!.text
                              : '📷 Photo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: ChatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: ChatColors.textLight),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),

          // Input Control Bar matching Reference Screenshot
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatDimensions.paddingM,
              vertical: ChatDimensions.paddingS,
            ),
            decoration: const BoxDecoration(
              color: ChatColors.pageBackground,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: ChatColors.primaryPurple,
                      size: 26,
                    ),
                    onPressed: _isUploading ? null : _showMediaPickerOptions,
                    tooltip: 'Attachments',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isUploading,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: ChatDecorations.inputDecoration('Type a message...'),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: ChatColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: _isUploading
                        ? null
                        : () => _pickAndConfirmImage(ImageSource.camera),
                    tooltip: 'Camera',
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _isUploading ? null : () => _handleSend(),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _isUploading ? ChatColors.offlineGrey : ChatColors.primaryPurple,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x207B38E0),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
