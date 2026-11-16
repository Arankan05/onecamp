import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus { ringing, connecting, active, declined, ended, missed }

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String targetId;
  final String targetName;
  final String chatId;
  final bool isVideo;
  final CallStatus status;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.targetId,
    required this.targetName,
    required this.chatId,
    required this.isVideo,
    required this.status,
    this.offer,
    this.answer,
  });

  factory CallModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    CallStatus parseStatus(String? val) {
      switch (val) {
        case 'ringing':
          return CallStatus.ringing;
        case 'connecting':
          return CallStatus.connecting;
        case 'active':
          return CallStatus.active;
        case 'declined':
          return CallStatus.declined;
        case 'ended':
          return CallStatus.ended;
        case 'missed':
          return CallStatus.missed;
        default:
          return CallStatus.ended;
      }
    }

    return CallModel(
      callId: doc.id,
      callerId: data['callerId'] as String? ?? '',
      callerName: data['callerName'] as String? ?? 'Caller',
      targetId: data['targetId'] as String? ?? '',
      targetName: data['targetName'] as String? ?? 'Recipient',
      chatId: data['chatId'] as String? ?? '',
      isVideo: data['isVideo'] as bool? ?? false,
      status: parseStatus(data['status'] as String?),
      offer: data['offer'] as Map<String, dynamic>?,
      answer: data['answer'] as Map<String, dynamic>?,
    );
  }
}

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Map<String, dynamic> _iceConfiguration = {
    'iceServers': [
      {'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']},
    ]
  };

  /// Stream incoming ringing calls for the current user.
  Stream<CallModel?> getIncomingCallsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('calls')
        .where('targetId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CallModel.fromDocument(snapshot.docs.first);
    });
  }

  /// Stream updates for a specific active call document.
  Stream<CallModel?> getCallStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return CallModel.fromDocument(snapshot);
    });
  }

  /// Start an outgoing audio or video WebRTC call.
  Future<String> startCall({
    required String targetId,
    required String targetName,
    required String chatId,
    required bool isVideo,
    required RTCVideoRenderer localRenderer,
    required RTCVideoRenderer remoteRenderer,
    required Function(RTCPeerConnection pc) onPeerConnectionCreated,
  }) async {
    final callerUid = _auth.currentUser?.uid;
    if (callerUid == null) throw Exception('Must be signed in to call.');

    final callerName = _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Student';

    final callDocRef = _firestore.collection('calls').doc();
    final callId = callDocRef.id;

    // Create RTCPeerConnection
    final RTCPeerConnection pc = await createPeerConnection(_iceConfiguration);
    onPeerConnectionCreated(pc);

    // Get User Media (Camera / Microphone)
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    };

    final MediaStream localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = localStream;

    localStream.getTracks().forEach((track) {
      pc.addTrack(track, localStream);
    });

    // Listen for Remote Stream Tracks
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    // Collect Caller ICE Candidates -> Firestore offerCandidates
    final offerCandidatesRef = callDocRef.collection('offerCandidates');
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      offerCandidatesRef.add(candidate.toMap());
    };

    // Create SDP Offer
    final RTCSessionDescription offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    // Save Call Document to Firestore
    await callDocRef.set({
      'callerId': callerUid,
      'callerName': callerName,
      'targetId': targetId,
      'targetName': targetName,
      'chatId': chatId,
      'isVideo': isVideo,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });

    // Listen for SDP Answer from Target
    callDocRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      final remoteDesc = await pc.getRemoteDescription();
      if (data != null && data['answer'] != null && remoteDesc == null) {
        final answerMap = data['answer'] as Map<String, dynamic>;
        final answer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
        await pc.setRemoteDescription(answer);

        // Update call status to active
        await callDocRef.update({'status': 'active'});
      }
    });

    // Listen for Answer Candidates from Target
    callDocRef.collection('answerCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            pc.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        }
      }
    });

    return callId;
  }

  /// Accept an incoming WebRTC call.
  Future<void> acceptCall({
    required CallModel call,
    required RTCVideoRenderer localRenderer,
    required RTCVideoRenderer remoteRenderer,
    required Function(RTCPeerConnection pc) onPeerConnectionCreated,
  }) async {
    final callDocRef = _firestore.collection('calls').doc(call.callId);

    final RTCPeerConnection pc = await createPeerConnection(_iceConfiguration);
    onPeerConnectionCreated(pc);

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': call.isVideo ? {'facingMode': 'user'} : false,
    };

    final MediaStream localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = localStream;

    localStream.getTracks().forEach((track) {
      pc.addTrack(track, localStream);
    });

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    final answerCandidatesRef = callDocRef.collection('answerCandidates');
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      answerCandidatesRef.add(candidate.toMap());
    };

    // Set Remote Description from Caller Offer
    if (call.offer != null) {
      final offer = RTCSessionDescription(call.offer!['sdp'], call.offer!['type']);
      await pc.setRemoteDescription(offer);
    }

    // Create SDP Answer
    final RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await callDocRef.update({
      'status': 'connecting',
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });

    // Listen for Offer Candidates from Caller
    callDocRef.collection('offerCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            pc.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        }
      }
    });
  }

  /// Decline an incoming call.
  Future<void> declineCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'declined',
    });
  }

  /// End an active or ringing call.
  Future<void> endCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
    });
  }
}
