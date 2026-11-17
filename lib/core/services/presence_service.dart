import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService with WidgetsBindingObserver {
  static const String databaseUrl =
      'https://onecamp-8ebce-default-rtdb.asia-southeast1.firebasedatabase.app/';

  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;

  PresenceService._internal();

  FirebaseDatabase? _database;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  StreamSubscription<User?>? _authSubscription;
  DatabaseReference? _myConnectionRef;

  bool _isInitialized = false;

  void initialize({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) {
    if (_isInitialized) return;

    _database =
        database ??
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: databaseUrl,
        );
    _auth = auth ?? FirebaseAuth.instance;
    _firestore = firestore ?? FirebaseFirestore.instance;

    WidgetsBinding.instance.addObserver(this);

    _authSubscription = _auth!.authStateChanges().listen((User? user) {
      if (user != null) {
        _configurePresence(user.uid);
      } else {
        _cleanup();
      }
    });

    _isInitialized = true;
  }

  void _configurePresence(String uid) {
    if (_database == null) return;

    _cleanupSessionConnection();

    final DatabaseReference userConnectionsRef = _database!.ref(
      'status/$uid/connections',
    );
    final DatabaseReference lastSeenRef = _database!.ref(
      'status/$uid/lastSeen',
    );
    final DatabaseReference connectedRef = _database!.ref('.info/connected');

    _connectionSubscription = connectedRef.onValue.listen((
      DatabaseEvent event,
    ) {
      final bool isConnected = (event.snapshot.value as bool?) ?? false;

      if (isConnected) {
        // Create a unique connection node for this specific device/session
        _myConnectionRef = userConnectionsRef.push();

        // 1. On disconnect: remove this device's connection node
        _myConnectionRef!.onDisconnect().remove();

        // 2. On disconnect: update lastSeen timestamp
        lastSeenRef.onDisconnect().set(ServerValue.timestamp);

        // 3. Mark this device as connected
        _myConnectionRef!.set(true);

        // Sync Firestore profile status
        _firestore
            ?.collection('users')
            .doc(uid)
            .update({'isOnline': true})
            .catchError((_) {});
      }
    });
  }

  void setOffline() {
    final uid = _auth?.currentUser?.uid;
    _cleanupSessionConnection();

    if (uid != null && _database != null) {
      _database!.ref('status/$uid/lastSeen').set(ServerValue.timestamp);
      _firestore
          ?.collection('users')
          .doc(uid)
          .update({'isOnline': false})
          .catchError((_) {});
    }
  }

  void setOnline() {
    final uid = _auth?.currentUser?.uid;
    if (uid != null) {
      _configurePresence(uid);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      setOffline();
    }
  }

  /// Stream real-time set of user UIDs who have at least one active connection in RTDB.
  Stream<Set<String>> getOnlineUserUidsStream() {
    if (_database == null) return Stream.value({});

    return _database!.ref('status').onValue.map((event) {
      final Set<String> onlineUids = {};
      final rawData = event.snapshot.value;

      if (rawData is Map) {
        rawData.forEach((uidKey, userStatus) {
          if (userStatus is Map) {
            final connections = userStatus['connections'];
            if (connections is Map && connections.isNotEmpty) {
              final bool hasValidConnection = connections.values.any(
                (v) => v != null,
              );
              if (hasValidConnection) {
                onlineUids.add(uidKey.toString());
              }
            }
          }
        });
      }

      return onlineUids;
    });
  }

  /// Stream real-time online boolean for a user UID from RTDB multi-device connections node.
  Stream<bool> getUserOnlineStream(String uid) {
    if (_database == null) return Stream.value(false);

    return _database!.ref('status/$uid/connections').onValue.map((event) {
      final connectionsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      return connectionsMap != null && connectionsMap.isNotEmpty;
    });
  }

  /// Stream presence metadata (isOnline, lastSeen) for a user from RTDB.
  Stream<Map<String, dynamic>> getUserPresenceStream(String uid) {
    if (_database == null)
      return Stream.value({'isOnline': false, 'lastSeen': null});

    return _database!.ref('status/$uid').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {'isOnline': false, 'lastSeen': null};

      final connectionsMap = data['connections'] as Map<dynamic, dynamic>?;
      final bool isOnline = connectionsMap != null && connectionsMap.isNotEmpty;

      final dynamic rawLastSeen = data['lastSeen'];
      DateTime? lastSeen;
      if (rawLastSeen is int) {
        lastSeen = DateTime.fromMillisecondsSinceEpoch(rawLastSeen);
      }

      return {'isOnline': isOnline, 'lastSeen': lastSeen};
    });
  }

  void _cleanupSessionConnection() {
    if (_myConnectionRef != null) {
      _myConnectionRef!.remove();
      _myConnectionRef = null;
    }
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }

  void _cleanup() {
    _cleanupSessionConnection();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    _authSubscription?.cancel();
    _isInitialized = false;
  }
}
