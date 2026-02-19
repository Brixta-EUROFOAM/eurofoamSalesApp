import 'package:flutter/foundation.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/services/websocket/sync_worker.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._();
  SessionManager._();
  static SessionManager get instance => _instance;
  
  int? _userId;
  SyncWorker? _syncWorker;

  bool get isLoggedIn => _userId != null;
  int get userId => _userId!;

  // 🚀 START SESSION
  Future<void> startSession(int userId) async {
    if (_syncWorker != null) return; // already running

    _userId = userId;
    //const serverUrl = 'ws://10.0.2.2:8000'; 
    final String serverUrl = kReleaseMode ? 'ws://65.0.208.126' : 'wss://myserver2-5ame.onrender.com';

    _syncWorker = SyncWorker(
      db: AppDatabase.instance,
      wsUrl: serverUrl,
      userId: userId,
    );

    await _syncWorker!.start();
  }

  // 📢 Helper to wake up the worker
  void triggerSync() {
    _syncWorker?.triggerSync();
  }

  // 🛑 LOGOUT
  Future<void> clear() async {
    await _syncWorker?.stop();
    _syncWorker = null;
    _userId = null;
  }
}