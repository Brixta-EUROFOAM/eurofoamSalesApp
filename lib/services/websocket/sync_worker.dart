import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/services/websocket/socket_client.dart';

class SyncWorker {
  final AppDatabase db;
  final String wsUrl;
  final int userId;

  late SocketClient _socket;
  bool _isSyncing = false;
  Timer? _retryTimer;

  SyncWorker({required this.db, required this.wsUrl, required this.userId}) {
    // Initialize Socket Client
    _socket = SocketClient(wsUrl);

    // 1. When connected -> Check DB for pending items
    _socket.onConnect = () {
      debugPrint("✅ [SyncWorker] Socket Connected. Flushing queue...");
      _cancelRetry();
      flushQueue();
    };

    // 2. When disconnected -> Start retry timer
    _socket.onDisconnect = () {
      debugPrint("❌ [SyncWorker] Socket Disconnected.");
      _scheduleRetry();
    };

    // 3. When message received -> Handle ACKs
    _socket.onMessage = (data) async {
      if (data['type'] == 'ACK') {
        await _handleAck(data['payload']);
      }
    };
  }

  // 🚀 Start the worker
  Future<void> start() async {
    debugPrint('🟢 SyncWorker.start()');
    _socket.connect();
  }

  // 🛑 Stop the worker
  Future<void> stop() async {
    debugPrint('🛑 SyncWorker.stop()');
    _cancelRetry();
    _socket.close();
  }

  // 📤 FLUSH: Send pending items to server
  Future<void> flushQueue() async {
    if (_isSyncing) return;
    if (!_socket.isConnected) return;

    final pendingOps = await db.getPendingOps();
    if (pendingOps.isEmpty) return;

    _isSyncing = true;

    debugPrint("📤 [SyncWorker] Sending ${pendingOps.length} ops...");

    final payload = pendingOps.map((op) {
      return {
        'opId': op.opId,
        'journeyId': op.journeyId,
        'userId': op.userId,
        'type': op.type,
        'payload': jsonDecode(op.payload),
        'createdAt': op.createdAt.toIso8601String(),
      };
    }).toList();

    try {
      _socket.send({'type': 'SYNC_OPS', 'payload': payload});

      // 🚀 FIX: Failsafe timer! If we don't get an ACK in 10 seconds, unlock so we can retry.
      Timer(const Duration(seconds: 10), () {
        if (_isSyncing) {
          debugPrint("⚠️ [SyncWorker] ACK Timeout! Unlocking queue for retry.");
          _isSyncing = false;
        }
      });
    } catch (e) {
      debugPrint("🚨 [SyncWorker] Failed to send: $e");
      _isSyncing = false; // Unlock if sending crashes
    }
  }

  // 📥 ACK: Server confirmed receipt
  Future<void> _handleAck(dynamic payload) async {
    final acks = payload as List;
    final List<String> successIds = [];

    for (var ack in acks) {
      if (ack['status'] == 'OK' || ack['status'] == 'ALREADY_PROCESSED') {
        successIds.add(ack['opId']);
      }
    }

    if (successIds.isNotEmpty) {
      await db.deleteOps(successIds);
      debugPrint("✅ [SyncWorker] Synced & Deleted ${successIds.length} ops.");
    }

    // 🔓 RELEASE LOCK
    _isSyncing = false;

    // 🔁 CHECK IF MORE OPS ARRIVED WHILE SENDING
    flushQueue();
  }

  // 🔄 RETRY LOGIC
  void _scheduleRetry() {
    _cancelRetry();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      debugPrint("🔄 [SyncWorker] Retrying connection...");
      _socket.connect();
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void triggerSync() {
    debugPrint("⚡ [SyncWorker] triggerSync()");

    if (_socket.isConnected) {
      flushQueue();
    } else {
      // Ensure a retry happens
      _scheduleRetry();
    }
  }
}
