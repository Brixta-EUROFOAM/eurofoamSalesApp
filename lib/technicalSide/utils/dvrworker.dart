import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_visit_report_model.dart';
import 'package:salesmanapp/database/app_database.dart'; // 🚀 Added Drift DB

class DvrBackgroundWorker {
  // --- 🛡️ 1. FILE DURABILITY (Prevents OS from deleting photos) ---
  static bool _isSyncing = false;

  static Future<String?> _saveFilePermanently(String? tempPath) async {
    if (tempPath == null) return null;
    final tempFile = File(tempPath);
    if (!await tempFile.exists()) return null;

    final docDir = await getApplicationDocumentsDirectory();
    final permanentDir = Directory(p.join(docDir.path, 'offline_dvr_media'));
    if (!await permanentDir.exists()) {
      await permanentDir.create(recursive: true);
    }

    final fileName = p.basename(tempPath);
    final permanentFile = await tempFile.copy(
      p.join(permanentDir.path, fileName),
    );
    return permanentFile.path;
  }

  static Future<void> processAndSubmit({
    required ApiService apiService,
    required DailyVisitReport dvrPayload,
    required File? inTimeFile,
    required File outTimeFile,
    required List<File> evidenceFiles,
    required bool clearDrafts,
  }) async {
    if (clearDrafts) _clearUiDrafts();

    final permIn = await _saveFilePermanently(inTimeFile?.path);
    final permOut = await _saveFilePermanently(outTimeFile.path);

    final Map<String, dynamic> payload = dvrPayload.toJson();
    payload['local_in_image'] = permIn;
    payload['local_out_image'] = permOut;
    payload['reportDate'] = dvrPayload.reportDate.toIso8601String();
    payload['checkInTime'] = dvrPayload.checkInTime.toIso8601String();
    payload['checkOutTime'] = dvrPayload.checkOutTime?.toIso8601String();

    List<String> filesToUpload = [];
    if (permIn != null) filesToUpload.add(permIn);
    if (permOut != null) filesToUpload.add(permOut);

    await AppDatabase.instance.enqueueOfflineTask(
      entityType: 'DVR',
      payload: payload,
      filePaths: filesToUpload.isNotEmpty ? filesToUpload : null,
    );

    debugPrint("📦 [DVR Worker] Payload safely locked in SQLite Vault.");

    retryStuckQueue(apiService).catchError((e) {
      debugPrint("⚠️ [DVR Worker] Offline. Sync paused and queued.");
    });
  }

  // --- 🔄 3. THE "FLUSH" SYSTEM (Chunked Processor) ---
  static Future<void> retryStuckQueue(
    ApiService apiService, {
    BuildContext? context,
  }) async {
    // 🛡️ THE LOCK: If we are already uploading, abort this trigger!
    if (_isSyncing) {
      debugPrint(
        "⏳ [DVR Worker] Sync already in progress. Ignoring duplicate trigger.",
      );
      return;
    }

    final db = AppDatabase.instance;
    final pendingTasks = await db.getPendingSyncTasks(limit: 5);

    if (pendingTasks.isEmpty) {
      return;
    }

    // 🔒 LOCK ENGAGED
    _isSyncing = true;
    debugPrint(
      "🔄 [DVR Worker] Network restored! Processing ${pendingTasks.length} queued tasks...",
    );

    // 📢 UI NOTIFICATION: Tell the user the engine is running
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.sync, color: Colors.white),
              SizedBox(width: 10),
              Text("Network Restored: Syncing offline data..."),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }

    int successCount = 0;

    for (final task in pendingTasks) {
      bool success = false;
      try {
        if (task.entityType == 'DVR') {
          success = await _executeDvrUploadTask(task, apiService);
        } else if (task.entityType == 'DEALER_PATCH') {
          success = true;
        }

        if (success) {
          await db.markSyncTaskComplete(task.id);
          successCount++;
          debugPrint(
            "✅ [DVR Worker] Task ${task.id} SYNCED & Removed from Queue.",
          );
        } else {
          await db.markSyncTaskFailed(task.id, task.retryCount);
        }
      } catch (e) {
        debugPrint("🔴 [DVR Worker] Task ${task.id} CRASHED: $e");
        await db.markSyncTaskFailed(task.id, task.retryCount);
      }
    }

    // 🔓 LOCK RELEASED
    _isSyncing = false;

    // 📢 UI NOTIFICATION: Tell the user it finished
    if (successCount > 0 && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Successfully synced $successCount offline items!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // ♻️ RECURSIVE FLUSH
    if (pendingTasks.length == 5) {
      await retryStuckQueue(apiService, context: context);
    }
  }

  // --- ⚙️ 4. INTERNAL WORKER (The Heavy Lifter) ---
  static Future<bool> _executeDvrUploadTask(
    SyncQueueData task,
    ApiService apiService,
  ) async {
    final Map<String, dynamic> payload = jsonDecode(task.payload);
    String? inUrl;
    String? outUrl;

    Future<String?> uploadImage(String? localPath) async {
      if (localPath == null) return null;
      final file = File(localPath);
      if (await file.exists()) {
        // 🚀 CRITICAL FIX: Wrap in a try-catch that explicitly throws
        try {
          return await apiService.uploadImageToR2(file);
        } catch (e) {
          debugPrint("⚠️ Image upload failed: $e");
          // Throwing an exception here acts as an emergency brake.
          // It aborts the entire _executeDvrUploadTask, keeping the task in the
          // SQLite queue to retry later, saving your photos from being deleted!
          throw Exception(
            "Network too weak to upload image. Aborting task for retry.",
          );
        }
      }
      return null;
    }

    // 1. Upload both images concurrently. If either fails, it throws and stops here.
    final results = await Future.wait([
      uploadImage(payload['local_in_image']),
      uploadImage(payload['local_out_image']),
    ]);

    inUrl = results[0];
    outUrl = results[1];

    // 2. Remove local paths from payload before sending to API
    payload.remove('local_in_image');
    payload.remove('local_out_image');

    DailyVisitReport dvr = DailyVisitReport.fromJson(payload);
    dvr = dvr.copyWith(
      inTimeImageUrl: inUrl ?? dvr.inTimeImageUrl,
      outTimeImageUrl: outUrl ?? dvr.outTimeImageUrl,
    );

    // 3. Submit the final DVR to the server. (If this fails, it throws and stops here)
    await apiService.createDvr(dvr);

    // 4. CLEANUP: This ONLY runs if BOTH images AND the DVR API call were 100% successful.
    final inPath = jsonDecode(task.payload)['local_in_image'];
    final outPath = jsonDecode(task.payload)['local_out_image'];
    if (inPath != null) {
      try {
        await File(inPath).delete();
      } catch (_) {}
    }
    if (outPath != null) {
      try {
        await File(outPath).delete();
      } catch (_) {}
    }

    return true; // Tells the worker to permanently remove this task from the SQLite queue
  }

  static Future<void> _clearUiDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final futures = <Future<bool>>[];
    for (String key in allKeys) {
      if (key.startsWith('dvr_ctrl_') || key.startsWith('dvr_val_')) {
        futures.add(prefs.remove(key));
      }
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }
}

// --- 🛠️ HELPER EXTENSION ---
extension DvrCopyWith on DailyVisitReport {
  DailyVisitReport copyWith({
    String? inTimeImageUrl,
    String? outTimeImageUrl,
    String? customerType,
    String? partyType,
    String? nameOfParty,
    String? contactNoOfParty,
    DateTime? expectedActivationDate,
  }) {
    return DailyVisitReport(
      id: id,
      idempotencyKey: idempotencyKey, // 🚀 Keep the fingerprint
      dailyTaskId: dailyTaskId,
      userId: userId,
      dealerId: dealerId,
      subDealerId: subDealerId,
      reportDate: reportDate,
      dealerType: dealerType,
      dealerName: dealerName,
      subDealerName: subDealerName,
      overdueAmount: overdueAmount,
      timeSpentinLoc: timeSpentinLoc,
      customerType: customerType ?? this.customerType,
      partyType: partyType ?? this.partyType,
      nameOfParty: nameOfParty ?? this.nameOfParty,
      contactNoOfParty: contactNoOfParty ?? this.contactNoOfParty,
      expectedActivationDate:
          expectedActivationDate ?? this.expectedActivationDate,
      location: location,
      latitude: latitude,
      longitude: longitude,
      visitType: visitType,
      dealerTotalPotential: dealerTotalPotential,
      dealerBestPotential: dealerBestPotential,
      brandSelling: brandSelling,
      contactPerson: contactPerson,
      contactPersonPhoneNo: contactPersonPhoneNo,
      todayOrderMt: todayOrderMt,
      todayCollectionRupees: todayCollectionRupees,
      feedbacks: feedbacks,
      solutionBySalesperson: solutionBySalesperson,
      anyRemarks: anyRemarks,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pjpId: pjpId,
      inTimeImageUrl: inTimeImageUrl ?? this.inTimeImageUrl,
      outTimeImageUrl: outTimeImageUrl ?? this.outTimeImageUrl,
    );
  }
}
