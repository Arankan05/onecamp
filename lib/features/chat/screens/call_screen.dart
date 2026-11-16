import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/services/call_service.dart';
import '../theme/chat_colors.dart';
import '../widgets/chat_avatar.dart';

class CallScreen extends StatefulWidget {
  final CallModel? initialCall;
  final String? targetId;
  final String? targetName;
  final String? chatId;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    this.initialCall,
    this.targetId,
    this.targetName,
    this.chatId,
    this.isVideo = false,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  StreamSubscription<CallModel?>? _callSubscription;
  CallModel? _currentCall;

  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  bool _isCallConnected = false;
  String _callStatusText = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    if (widget.isIncoming && widget.initialCall != null) {
      _currentCall = widget.initialCall;
      _callStatusText = 'Incoming ${widget.initialCall!.isVideo ? 'Video' : 'Audio'} Call...';
      _subscribeToCall(widget.initialCall!.callId);
    } else if (widget.targetId != null && widget.chatId != null) {
      _startOutgoingCall();
    }
  }

  void _subscribeToCall(String callId) {
    _callSubscription = _callService.getCallStream(callId).listen((call) {
      if (!mounted) return;

      if (call == null || call.status == CallStatus.ended || call.status == CallStatus.declined) {
        _endCallAndPop(statusMessage: 'Call ${call?.status == CallStatus.declined ? 'Declined' : 'Ended'}');
        return;
      }

      setState(() {
        _currentCall = call;
        if (call.status == CallStatus.active) {
          _isCallConnected = true;
          _callStatusText = 'Connected';
        } else if (call.status == CallStatus.ringing) {
          _callStatusText = 'Ringing...';
        } else if (call.status == CallStatus.connecting) {
          _callStatusText = 'Connecting...';
        }
      });
    });
  }

  Future<void> _startOutgoingCall() async {
    try {
      setState(() => _callStatusText = 'Calling ${widget.targetName ?? 'Student'}...');

      final callId = await _callService.startCall(
        targetId: widget.targetId!,
        targetName: widget.targetName ?? 'Student',
        chatId: widget.chatId!,
        isVideo: widget.isVideo,
        localRenderer: _localRenderer,
        remoteRenderer: _remoteRenderer,
        onPeerConnectionCreated: (pc) {
          _peerConnection = pc;
        },
      );

      _subscribeToCall(callId);
    } catch (e) {
      _endCallAndPop(statusMessage: 'Call Failed: $e');
    }
  }

  Future<void> _acceptIncomingCall() async {
    if (_currentCall == null) return;

    try {
      setState(() => _callStatusText = 'Connecting...');

      await _callService.acceptCall(
        call: _currentCall!,
        localRenderer: _localRenderer,
        remoteRenderer: _remoteRenderer,
        onPeerConnectionCreated: (pc) {
          _peerConnection = pc;
        },
      );
    } catch (e) {
      _endCallAndPop(statusMessage: 'Failed to accept call: $e');
    }
  }

  void _toggleMute() {
    if (_peerConnection != null) {
      final audioTracks = _localRenderer.srcObject?.getAudioTracks();
      if (audioTracks != null && audioTracks.isNotEmpty) {
        setState(() {
          _isAudioMuted = !_isAudioMuted;
          audioTracks.first.enabled = !_isAudioMuted;
        });
      }
    }
  }

  void _toggleVideo() {
    if (_peerConnection != null) {
      final videoTracks = _localRenderer.srcObject?.getVideoTracks();
      if (videoTracks != null && videoTracks.isNotEmpty) {
        setState(() {
          _isVideoOff = !_isVideoOff;
          videoTracks.first.enabled = !_isVideoOff;
        });
      }
    }
  }

  void _switchCamera() {
    if (_localRenderer.srcObject != null) {
      final videoTrack = _localRenderer.srcObject!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        Helper.switchCamera(videoTrack);
      }
    }
  }

  Future<void> _endCallAndPop({String? statusMessage}) async {
    if (_currentCall != null) {
      await _callService.endCall(_currentCall!.callId);
    }

    _callSubscription?.cancel();
    _peerConnection?.close();
    _localRenderer.srcObject?.getTracks().forEach((t) => t.stop());
    _remoteRenderer.srcObject?.getTracks().forEach((t) => t.stop());

    if (mounted) {
      if (statusMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(statusMessage)),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideoCall = widget.isVideo || (_currentCall?.isVideo ?? false);
    final String displayName = widget.targetName ?? _currentCall?.callerName ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1433),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video Renderer / Background View
            if (isVideoCall && _isCallConnected)
              Positioned.fill(
                child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChatAvatar(
                      name: displayName,
                      size: 110,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _callStatusText,
                      style: const TextStyle(
                        fontSize: 15,
                        color: ChatColors.accentLavender,
                      ),
                    ),
                  ],
                ),
              ),

            // Local Video Overlay Preview (Video Call)
            if (isVideoCall && !_isVideoOff)
              Positioned(
                right: 20,
                top: 30,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.black54,
                    child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
              ),

            // Call Controls Overlay Bottom Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Incoming Call Action Buttons (Accept / Reject)
                  if (widget.isIncoming && !_isCallConnected && _currentCall?.status == CallStatus.ringing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: 'reject_btn',
                          backgroundColor: Colors.redAccent,
                          onPressed: () => _endCallAndPop(statusMessage: 'Call Declined'),
                          child: const Icon(Icons.call_end, color: Colors.white),
                        ),
                        FloatingActionButton(
                          heroTag: 'accept_btn',
                          backgroundColor: ChatColors.onlineGreen,
                          onPressed: _acceptIncomingCall,
                          child: const Icon(Icons.call, color: Colors.white),
                        ),
                      ],
                    )
                  else
                    // Active / Outgoing Call Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Mic Button
                        IconButton(
                          icon: Icon(_isAudioMuted ? Icons.mic_off : Icons.mic),
                          color: Colors.white,
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            backgroundColor: _isAudioMuted ? Colors.redAccent : const Color(0x33FFFFFF),
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: _toggleMute,
                        ),

                        // End Call Button
                        FloatingActionButton(
                          heroTag: 'end_call_btn',
                          backgroundColor: Colors.redAccent,
                          elevation: 6,
                          onPressed: () => _endCallAndPop(),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                        ),

                        // Camera Off Button (Video Call Only)
                        if (isVideoCall)
                          IconButton(
                            icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                            color: Colors.white,
                            iconSize: 28,
                            style: IconButton.styleFrom(
                              backgroundColor: _isVideoOff ? Colors.redAccent : const Color(0x33FFFFFF),
                              padding: const EdgeInsets.all(16),
                            ),
                            onPressed: _toggleVideo,
                          ),

                        // Switch Camera Button (Video Call Only)
                        if (isVideoCall)
                          IconButton(
                            icon: const Icon(Icons.cameraswitch),
                            color: Colors.white,
                            iconSize: 28,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0x33FFFFFF),
                              padding: const EdgeInsets.all(16),
                            ),
                            onPressed: _switchCamera,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
