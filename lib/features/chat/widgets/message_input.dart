import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/cloudinary_upload_service.dart';
import '../models/message_model.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(String imageUrl)? onSendImage;
  final Function(
    String mediaUrl,
    String fileName,
    int fileSize,
    String fileExtension,
  )?
  onSendDocument;
  final Function(
    String mediaUrl,
    String fileName,
    int fileSize,
    int durationSeconds,
  )?
  onSendAudio;
  final Function(String mediaUrl, int durationSeconds)? onSendVoice;
  final MessageModel? replyingToMessage;
  final String? replyingToSenderName;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSendText,
    this.onSendImage,
    this.onSendDocument,
    this.onSendAudio,
    this.onSendVoice,
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
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPreviewing = false;
  bool _isPlayingPreview = false;
  AudioPlayer? _previewPlayer;
  bool _showEmojiPicker = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordedFilePath;

  final List<String> _quickSuggestions = [
    'Sounds good!',
    'On my way',
    'Send location',
  ];

  final List<String> _emojis = [
    '😀',
    '😂',
    '🥰',
    '😍',
    '😎',
    '😊',
    '🤔',
    '😭',
    '🔥',
    '❤️',
    '👍',
    '👍🏽',
    '🙏',
    '🙌',
    '👏',
    '🙋‍♂️',
    '🎉',
    '✨',
    '💯',
    '🚀',
    '📚',
    '🎓',
    '💻',
    '⚽',
    '☕',
    '👋',
    '⭐',
    '💡',
    '📌',
    '👀',
    '💪',
  ];

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = selection.start >= 0
        ? text.replaceRange(selection.start, selection.end, emoji)
        : text + emoji;
    _controller.text = newText;
    final newCursorOffset =
        (selection.start >= 0 ? selection.start : text.length) + emoji.length;
    _controller.selection = TextSelection.collapsed(offset: newCursorOffset);
  }

  void _handleSend([String? textToSend]) {
    if (_isUploading || _isRecording) return;
    final text = textToSend ?? _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      if (textToSend == null) {
        _controller.clear();
      }
      if (widget.onCancelReply != null) {
        widget.onCancelReply!();
      }
      setState(() => _showEmojiPicker = false);
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
          padding: const EdgeInsets.symmetric(
            vertical: ChatDimensions.paddingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: ChatColors.primaryPurple,
                ),
                title: const Text(
                  'Choose Photo from Gallery',
                  style: TextStyle(
                    color: Color(0xFF29213F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndConfirmImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: ChatColors.primaryPurple,
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Color(0xFF29213F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndConfirmImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file_outlined,
                  color: ChatColors.primaryPurple,
                ),
                title: const Text(
                  'Send Document (PDF, DOC, TXT)',
                  style: TextStyle(
                    color: Color(0xFF29213F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendDocument();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.audiotrack_outlined,
                  color: ChatColors.primaryPurple,
                ),
                title: const Text(
                  'Send Audio File (MP3, WAV, M4A)',
                  style: TextStyle(
                    color: Color(0xFF29213F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendAudioFile();
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
            content: Text(
              'Failed to select image: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'csv',
        ],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null)
        return;

      final PlatformFile file = result.files.first;
      final File localFile = File(file.path!);

      if (file.size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document size exceeds 20MB limit.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final String mediaUrl = await _uploadService.uploadFile(
        file: localFile,
        resourceType: 'auto',
      );

      if (widget.onSendDocument != null) {
        await widget.onSendDocument!(
          mediaUrl,
          file.name,
          file.size,
          file.extension ?? 'doc',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndSendAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null)
        return;

      final PlatformFile file = result.files.first;
      final File localFile = File(file.path!);

      if (file.size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio size exceeds 20MB limit.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final String mediaUrl = await _uploadService.uploadFile(
        file: localFile,
        resourceType: 'auto',
      );

      if (widget.onSendAudio != null) {
        await widget.onSendAudio!(mediaUrl, file.name, file.size, 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission required for voice recording.',
              ),
            ),
          );
        }
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _isPreviewing = false;
          _isPlayingPreview = false;
          _showEmojiPicker = false;
          _recordSeconds = 0;
          _recordedFilePath = path;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _recordSeconds++);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecordingForPreview() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isPreviewing = true;
      if (path != null) _recordedFilePath = path;
    });
  }

  Future<void> _togglePreviewPlayback() async {
    if (_recordedFilePath == null) return;
    if (_previewPlayer == null) {
      _previewPlayer = AudioPlayer();
      _previewPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _isPlayingPreview = state == PlayerState.playing);
        }
      });
    }

    if (_isPlayingPreview) {
      await _previewPlayer!.pause();
    } else {
      await _previewPlayer!.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _previewPlayer?.stop();
    try {
      await _audioRecorder.stop();
    } catch (_) {}

    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }

    setState(() {
      _isRecording = false;
      _isPreviewing = false;
      _isPlayingPreview = false;
      _recordSeconds = 0;
      _recordedFilePath = null;
    });
  }

  Future<void> _stopAndSendVoiceMessage() async {
    _recordTimer?.cancel();
    await _previewPlayer?.stop();

    String? path = _recordedFilePath;
    if (_isRecording) {
      path = await _audioRecorder.stop();
    }

    final duration = _recordSeconds;

    setState(() {
      _isRecording = false;
      _isPreviewing = false;
      _isPlayingPreview = false;
      _recordSeconds = 0;
    });

    final finalPath = path ?? _recordedFilePath;
    if (finalPath == null || !File(finalPath).existsSync()) return;

    try {
      setState(() => _isUploading = true);

      final String mediaUrl = await _uploadService.uploadFile(
        file: File(finalPath),
        resourceType: 'auto',
      );

      if (widget.onSendVoice != null) {
        await widget.onSendVoice!(mediaUrl, duration);
      }

      try {
        File(finalPath).deleteSync();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice message upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImagePreviewDialog(XFile imageFile) {
    String? dialogError;

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
                      borderRadius: BorderRadius.circular(
                        ChatDimensions.radiusS,
                      ),
                      child: Image.file(
                        File(imageFile.path),
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: ChatDimensions.paddingL),
                      const CircularProgressIndicator(
                        color: ChatColors.primaryPurple,
                      ),
                      const SizedBox(height: ChatDimensions.paddingS),
                      const Text(
                        'Uploading image...',
                        style: TextStyle(
                          fontSize: 12,
                          color: ChatColors.textSecondary,
                        ),
                      ),
                    ],
                    if (dialogError != null && !_isUploading) ...[
                      const SizedBox(height: ChatDimensions.paddingM),
                      Container(
                        padding: const EdgeInsets.all(ChatDimensions.paddingS),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(
                            ChatDimensions.radiusS,
                          ),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                      setDialogState(() {
                        _isUploading = true;
                        dialogError = null;
                      });
                      try {
                        final String secureUrl = await _uploadService
                            .uploadImage(imageFile);
                        if (widget.onSendImage != null) {
                          await widget.onSendImage!(secureUrl);
                        }
                        navigator.pop();
                      } catch (e) {
                        setDialogState(() {
                          _isUploading = false;
                          dialogError = e.toString().replaceAll(
                            'Exception: ',
                            '',
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: Text(
                      dialogError != null ? 'Retry Upload' : 'Send Photo',
                    ),
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

  String _formatDuration(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _previewPlayer?.dispose();
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChatColors.pageBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Suggestions Chips
          if (!_isRecording)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                children: _quickSuggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _handleSend(suggestion),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 8.0,
                      ),
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

          // Emoji Selector Toolbar
          if (_showEmojiPicker && !_isRecording)
            Container(
              height: 52,
              color: ChatColors.cardBackground,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  return GestureDetector(
                    onTap: () => _insertEmoji(emoji),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22.0),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Reply Preview Banner
          if (widget.replyingToMessage != null && !_isRecording)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
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
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: ChatColors.textLight,
                    ),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),

          // Live Voice Recording / Preview Control Banner
          if (_isRecording || _isPreviewing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: ChatColors.cardBackground,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: _cancelRecording,
                      tooltip: 'Discard recording',
                    ),
                    const SizedBox(width: 8),
                    if (_isPreviewing)
                      IconButton(
                        icon: Icon(
                          _isPlayingPreview
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: ChatColors.primaryPurple,
                          size: 32,
                        ),
                        onPressed: _togglePreviewPlayback,
                        tooltip: 'Preview recording',
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _isPreviewing
                          ? 'Preview Voice (${_formatDuration(_recordSeconds)})'
                          : 'Recording Voice... ${_formatDuration(_recordSeconds)}',
                      style: const TextStyle(
                        color: Color(0xFF29213F),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_isRecording)
                      IconButton(
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          color: ChatColors.primaryPurple,
                          size: 30,
                        ),
                        onPressed: _stopRecordingForPreview,
                        tooltip: 'Stop & Preview',
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _stopAndSendVoiceMessage,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 16),
                      label: Text(_isUploading ? 'Uploading...' : 'Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Standard Text / Media Control Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatDimensions.paddingM,
                vertical: ChatDimensions.paddingS,
              ),
              decoration: const BoxDecoration(color: ChatColors.pageBackground),
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
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.sentiment_satisfied_alt_outlined,
                        color: ChatColors.primaryPurple,
                        size: 24,
                      ),
                      onPressed: () =>
                          setState(() => _showEmojiPicker = !_showEmojiPicker),
                      tooltip: 'Emojis',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_isUploading,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        style: const TextStyle(
                          color: Color(0xFF29213F),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: const Color(0xFF7138D8),
                        decoration: ChatDecorations.inputDecoration(
                          'Type a message...',
                        ),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.mic_none_rounded,
                        color: ChatColors.primaryPurple,
                        size: 24,
                      ),
                      onPressed: _isUploading ? null : _startRecording,
                      tooltip: 'Record Voice Message',
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _isUploading ? null : () => _handleSend(),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: _isUploading
                              ? ChatColors.offlineGrey
                              : ChatColors.primaryPurple,
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
