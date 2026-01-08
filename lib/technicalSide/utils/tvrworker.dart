import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';

class TvrBackgroundWorker {
  
  // --- 🚀 PUBLIC ENTRY POINT (The "Fire & Forget" Trigger) ---
  static Future<void> processAndSubmit({
    required ApiService apiService,
    required TechnicalVisitReport tvrPayload,
    required File? inTimeFile,
    required File outTimeFile,
    required File? sitePhotoFile,
    required bool clearDrafts,
  }) async {
    
    // 1. Generate Unique ID (e.g., "1715609200000")
    final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 2. 💾 INSTANT DISK SAVE (The "Safety Box")
    // We save the raw paths and payload immediately. 
    // If the network dies or phone crashes, this JSON sits on the disk waiting.
    final backupData = {
      'id': taskId,
      'payload': tvrPayload.toJson(),
      'inTimePath': inTimeFile?.path,
      'outTimePath': outTimeFile.path,
      'sitePhotoPath': sitePhotoFile?.path,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _saveToSafetyBox(taskId, backupData);

    // 3. 🧹 Clear UI Drafts (Since we have the data safe on disk now)
    if (clearDrafts) {
      _clearUiDrafts(); 
    }

    // 4. ⚡ START UPLOAD (Independent "Thread")
    // We do NOT await this. We let the UI thread go free.
    _executeUploadTask(taskId, backupData, apiService).then((success) {
      if (success) {
        // 🌟 PIGGYBACK: If this succeeded, it means we have internet!
        // Let's quickly check if we have any stuck 9:00 AM reports and flush them.
        retryStuckQueue(apiService);
      }
    });
  }

  // --- ⚙️ INTERNAL WORKER (The Heavy Lifter) ---
  static Future<bool> _executeUploadTask(
    String taskId,
    Map<String, dynamic> data,
    ApiService apiService,
  ) async {
    debugPrint("🚀 [Worker] Processing Task: $taskId");

    try {
      // Rehydrate Model & Files from the saved JSON
      TechnicalVisitReport payload = TechnicalVisitReport.fromJson(data['payload']);
      final File? inTimeFile = data['inTimePath'] != null ? File(data['inTimePath']) : null;
      final File outTimeFile = File(data['outTimePath']);
      final File? sitePhotoFile = data['sitePhotoPath'] != null ? File(data['sitePhotoPath']) : null;

      // 1. Check-in Photo (Bite-sized upload)
      if (payload.inTimeImageUrl == null) {
        // Only upload if we have the file locally
        if (inTimeFile != null && await inTimeFile.exists()) {
             final url = await apiService.uploadImageToR2(inTimeFile);
             payload = payload.copyWith(inTimeImageUrl: url);
        } else {
           debugPrint("⚠️ [Worker] Warning: Check-in file missing for $taskId. Proceeding without.");
        }
      }

      // 2. Check-out Photo (Bite-sized upload)
      if (payload.outTimeImageUrl == null) { 
        if (await outTimeFile.exists()) {
           final outUrl = await apiService.uploadImageToR2(outTimeFile);
           payload = payload.copyWith(outTimeImageUrl: outUrl);
        }
      }

      // 3. Site Photo (Bite-sized upload)
      if (payload.sitePhotoUrl == null && sitePhotoFile != null) {
         if (await sitePhotoFile.exists()) {
            final siteUrl = await apiService.uploadImageToR2(sitePhotoFile);
            payload = payload.copyWith(sitePhotoUrl: siteUrl);
         }
      }

      // 4. Final Submission
      await apiService.createTvr(payload);

      // 5. ✅ SUCCESS: DESTROY DISK BACKUP
      // Only now do we remove it from the safety box.
      await _removeFromSafetyBox(taskId);
      debugPrint("✅ [Worker] Task $taskId COMPLETE & Removed from Queue.");
      return true;

    } catch (e) {
      debugPrint("🔴 [Worker] Task $taskId FAILED: $e");
      // ⚠️ IMPORTANT: We do NOT delete from Safety Box. 
      // It stays on disk to be retried later.
      return false;
    }
  }

  // --- 🔄 THE "FLUSH" SYSTEM (Bite-sized Retries) ---
  static Future<void> retryStuckQueue(ApiService apiService) async {
    final prefs = await SharedPreferences.getInstance();
    // Find all keys starting with 'queue_tvr_'
    final keys = prefs.getKeys().where((k) => k.startsWith('queue_tvr_')).toList();

    if (keys.isEmpty) return;

    debugPrint("🔄 [Worker] Found ${keys.length} stuck items. Flushing queue...");

    // We process them ONE BY ONE (Sequentially) to not choke the network.
    for (String key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) continue;

      final data = jsonDecode(jsonStr);
      final taskId = data['id'];

      debugPrint("🔄 [Worker] Retrying stuck task: $taskId");
      await _executeUploadTask(taskId, data, apiService);
      // We pause for 1 second between retries to keep it "bite-size"
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // --- 💾 DISK HELPERS ---
  static Future<void> _saveToSafetyBox(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('queue_tvr_$id', jsonEncode(data));
  }

  static Future<void> _removeFromSafetyBox(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('queue_tvr_$id');
  }

  static Future<void> _clearUiDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('tvr_ctrl_') || key.startsWith('tvr_val_')) {
        await prefs.remove(key);
      }
    }
  }
}


// --- 🛠️ HELPER EXTENSION (Paste this at bottom of file) ---
// This allows us to patch the model with new URLs without losing other data
extension TvrCopyWith on TechnicalVisitReport {
  TechnicalVisitReport copyWith({String? inTimeImageUrl, String? outTimeImageUrl, String? sitePhotoUrl}) {
    return TechnicalVisitReport(
      userId: userId, reportDate: reportDate, visitType: visitType, visitCategory: visitCategory,
      customerType: customerType, checkInTime: checkInTime, checkOutTime: checkOutTime,
      // Update fields if provided, else keep existing
      inTimeImageUrl: inTimeImageUrl ?? this.inTimeImageUrl,
      outTimeImageUrl: outTimeImageUrl ?? this.outTimeImageUrl,
      sitePhotoUrl: sitePhotoUrl ?? this.sitePhotoUrl,
      // Copy rest
      purposeOfVisit: purposeOfVisit, siteNameConcernedPerson: siteNameConcernedPerson,
      phoneNo: phoneNo, whatsappNo: whatsappNo, siteAddress: siteAddress, marketName: marketName,
      region: region, area: area, latitude: latitude, longitude: longitude,
      siteVisitStage: siteVisitStage, constAreaSqFt: constAreaSqFt, siteVisitBrandInUse: siteVisitBrandInUse,
      currentBrandPrice: currentBrandPrice, siteStock: siteStock, estRequirement: estRequirement,
      supplyingDealerName: supplyingDealerName, nearbyDealerName: nearbyDealerName,
      associatedPartyName: associatedPartyName, isConverted: isConverted, conversionType: conversionType,
      conversionFromBrand: conversionFromBrand, conversionQuantityValue: conversionQuantityValue,
      conversionQuantityUnit: conversionQuantityUnit, isTechService: isTechService,
      serviceDesc: serviceDesc, influencerName: influencerName, influencerPhone: influencerPhone,
      influencerProductivity: influencerProductivity, isSchemeEnrolled: isSchemeEnrolled,
      influencerType: influencerType, clientsRemarks: clientsRemarks, salespersonRemarks: salespersonRemarks,
      timeSpentinLoc: timeSpentinLoc, pjpId: pjpId, masonId: masonId, siteId: siteId, siteVisitType: siteVisitType
    );
  }
}