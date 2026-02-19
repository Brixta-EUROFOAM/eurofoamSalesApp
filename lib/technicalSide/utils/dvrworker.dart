// lib/utils/dvrworker.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_visit_report_model.dart';

class DvrBackgroundWorker {
  
  // --- 🚀 PUBLIC ENTRY POINT (The "Fire & Forget" Trigger) ---
  static Future<void> processAndSubmit({
    required ApiService apiService,
    required DailyVisitReport dvrPayload,
    required File? inTimeFile,
    required File outTimeFile,
    required List<File> evidenceFiles, 
    required bool clearDrafts,
  }) async {
    
    // 1. Generate Unique ID for the Queue
    final String queueId = "dvr_${DateTime.now().millisecondsSinceEpoch}";
    
    // 2. 💾 INSTANT DISK SAVE (The "Safety Box")
    final backupData = {
      'id': queueId,
      'payload': dvrPayload.toJson(),
      'inTimePath': inTimeFile?.path,
      'outTimePath': outTimeFile.path,
      'evidencePaths': evidenceFiles.map((f) => f.path).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _saveToSafetyBox(queueId, backupData);

    // 3. 🧹 Clear UI Drafts
    if (clearDrafts) {
      _clearUiDrafts(); 
    }

    // 4. ⚡ START UPLOAD
    final sanitizedData = jsonDecode(jsonEncode(backupData));

    _executeUploadTask(queueId, sanitizedData, apiService).then((success) {
      if (success) {
        retryStuckQueue(apiService);
      }
    });
  }

  // --- ⚙️ INTERNAL WORKER (The Heavy Lifter) ---
  static Future<bool> _executeUploadTask(
    String queueId,
    Map<String, dynamic> data,
    ApiService apiService,
  ) async {
    debugPrint("🚀 [DVR Worker] Processing Task: $queueId");

    try {
      DailyVisitReport payload = DailyVisitReport.fromJson(data['payload']);

      final File? inTimeFile = data['inTimePath'] != null ? File(data['inTimePath']) : null;
      final File outTimeFile = File(data['outTimePath']);

      // 1. Check-in Photo
      if (payload.inTimeImageUrl == null) {
        if (inTimeFile != null && await inTimeFile.exists()) {
             final url = await apiService.uploadImageToR2(inTimeFile);
             payload = payload.copyWith(inTimeImageUrl: url);
        }
      }

      // 2. Check-out Photo
      if (payload.outTimeImageUrl == null) { 
        if (await outTimeFile.exists()) {
           final outUrl = await apiService.uploadImageToR2(outTimeFile);
           payload = payload.copyWith(outTimeImageUrl: outUrl);
        }
      }

      // 3. Final Submission
      await apiService.createDvr(payload);

      // 4. ✅ SUCCESS: DESTROY DISK BACKUP
      await _removeFromSafetyBox(queueId);
      debugPrint("✅ [DVR Worker] Task $queueId COMPLETE & Removed from Queue.");
      return true;

    } catch (e) {
      debugPrint("🔴 [DVR Worker] Task $queueId FAILED: $e");
      return false;
    }
  }

  // --- 🔄 THE "FLUSH" SYSTEM ---
  static Future<void> retryStuckQueue(ApiService apiService) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('queue_dvr_')).toList();

    if (keys.isEmpty) return;

    debugPrint("🔄 [DVR Worker] Found ${keys.length} stuck items. Flushing...");

    for (String key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) continue;

      final data = jsonDecode(jsonStr);
      final queueId = data['id'];

      await _executeUploadTask(queueId, data, apiService);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // --- 💾 DISK HELPERS ---
  static Future<void> _saveToSafetyBox(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('queue_dvr_$id', jsonEncode(data));
  }

  static Future<void> _removeFromSafetyBox(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('queue_dvr_$id');
  }

  static Future<void> _clearUiDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('dvr_ctrl_') || key.startsWith('dvr_val_')) {
        await prefs.remove(key);
      }
    }
  }
}

// --- 🛠️ HELPER EXTENSION ---
extension DvrCopyWith on DailyVisitReport {
  DailyVisitReport copyWith({
    String? inTimeImageUrl,
    String? outTimeImageUrl,
    List<String>? photos, // kept for worker compatibility
  }) {
    return DailyVisitReport(
      // --- Existing Fields (Preserved) ---
      id: id,
      userId: userId,
      dealerId: dealerId,
      subDealerId: subDealerId,
      reportDate: reportDate,
      dealerType: dealerType,
      dealerName: dealerName,
      subDealerName: subDealerName,
      overdueAmount: overdueAmount,
      timeSpentinLoc: timeSpentinLoc,
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

      // --- Updated Fields ---
      inTimeImageUrl: inTimeImageUrl ?? this.inTimeImageUrl,
      outTimeImageUrl: outTimeImageUrl ?? this.outTimeImageUrl,
    );
  }
}