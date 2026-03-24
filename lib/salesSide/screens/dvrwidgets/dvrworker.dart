// lib/salesSide/screens/dvr_widgets/dvr_worker.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/daily_visit_report_model.dart';
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

    // Concurrently save files to permanent storage for extreme speed
    final savedFiles = await Future.wait([
      _saveFilePermanently(inTimeFile?.path),
      _saveFilePermanently(outTimeFile.path),
    ]);

    final permIn = savedFiles[0];
    final permOut = savedFiles[1];

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

  // --- 🔄 3. THE "FLUSH" SYSTEM (Optimized While-Loop Processor) ---
  static Future<void> retryStuckQueue(
    ApiService apiService, {
    BuildContext? context,
  }) async {
    // 🛡️ THE LOCK: Abort if already running
    if (_isSyncing) return;

    final db = AppDatabase.instance;
    bool hasMoreTasks = true;
    int totalSuccessCount = 0;

    _isSyncing = true; // 🔒 LOCK ENGAGED

    // 📢 UI NOTIFICATION: Tell the user the engine is running
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.sync, color: Colors.white),
              SizedBox(width: 6),
              Text("Network Restored: Syncing offline data..."),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      // 🚀 BATTERY SAVER: Replaced recursion with a memory-safe while loop
      while (hasMoreTasks) {
        final pendingTasks = await db.getPendingSyncTasks(limit: 5);

        if (pendingTasks.isEmpty) {
          hasMoreTasks = false;
          break;
        }

        debugPrint(
          "🔄 [DVR Worker] Processing ${pendingTasks.length} queued tasks...",
        );

        for (final task in pendingTasks) {
          bool success = false;
          try {
            if (task.entityType == 'DVR') {
              success = await _executeDvrUploadTask(task, apiService);
            } else if (task.entityType == 'DEALER_PATCH') {
              success = await _executeDealerPatchTask(task, apiService);
            }

            if (success) {
              await db.markSyncTaskComplete(task.id);
              totalSuccessCount++;
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

        // Give the CPU a 100ms breather to keep the UI smooth at 60fps
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      // 🔓 LOCK RELEASED (Always executes, even if loop crashes)
      _isSyncing = false;
    }

    // 📢 UI NOTIFICATION: Tell the user it finished
    if (totalSuccessCount > 0 && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Successfully synced $totalSuccessCount offline items!",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- ⚙️ 4. INTERNAL WORKER (The Heavy Lifter) ---
  static Future<bool> _executeDvrUploadTask(
    SyncQueueData task,
    ApiService apiService,
  ) async {
    // 🚀 TIME/SPACE OPTIMIZATION: Parse EXACTLY ONCE!
    final Map<String, dynamic> payload = jsonDecode(task.payload);

    // Cache the local paths BEFORE removing them from the payload
    final String? localInPath = payload['local_in_image'];
    final String? localOutPath = payload['local_out_image'];

    Future<String?> uploadImage(String? localPath) async {
      if (localPath == null) return null;
      final file = File(localPath);
      if (await file.exists()) {
        try {
          return await apiService.uploadImageToR2(file);
        } catch (e) {
          debugPrint("⚠️ Image upload failed: $e");
          throw Exception(
            "Network too weak to upload image. Aborting task for retry.",
          );
        }
      }
      return null;
    }

    // 1. Upload both images concurrently.
    final results = await Future.wait([
      uploadImage(localInPath),
      uploadImage(localOutPath),
    ]);

    // 2. Remove local paths from payload before sending to API
    payload.remove('local_in_image');
    payload.remove('local_out_image');

    DailyVisitReport dvr = DailyVisitReport.fromJson(payload);
    dvr = dvr.copyWith(
      inTimeImageUrl: results[0] ?? dvr.inTimeImageUrl,
      outTimeImageUrl: results[1] ?? dvr.outTimeImageUrl,
    );

    // 3. Submit the final DVR to the server.
    await apiService.createDvr(dvr);

    // 4. CLEANUP: Only runs if API call succeeds. Disk space saver!
    if (localInPath != null) {
      try {
        await File(localInPath).delete();
      } catch (_) {}
    }
    if (localOutPath != null) {
      try {
        await File(localOutPath).delete();
      } catch (_) {}
    }

    return true;
  }

  // --- ⚙️ 5. DEALER PATCH WORKER ---
  // 🚀 MEMORY FIX: Moved out of the loop so it doesn't allocate memory closures constantly
  static Future<bool> _executeDealerPatchTask(
    SyncQueueData task,
    ApiService apiService,
  ) async {
    final Map<String, dynamic> payload = jsonDecode(task.payload);
    final String dealerId = payload['dealerId'];
    final Map<String, dynamic> patchData = payload['patch'];

    try {
      await apiService.updateDealer(dealerId, patchData);
      debugPrint("✅ [DVR Worker] Successfully patched dealer: $dealerId");
      return true;
    } catch (e) {
      debugPrint(
        "⚠️ [DVR Worker] Dealer patch failed. Aborting task for retry: $e",
      );
      throw Exception("Failed to patch dealer: $e");
    }
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
