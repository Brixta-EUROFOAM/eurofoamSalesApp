// lib/services/update_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import '/main.dart'; 

class UpdateService {
  
  static Future<void> checkVersion() async {
    // Escape early if not on Android, as in_app_update is Android-specific
    if (!Platform.isAndroid) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );

      // Default fallbacks if Firebase can't be reached
      await remoteConfig.setDefaults(const {
        'min_required_version': 1,
        'force_update': false,
      });

      await remoteConfig.fetchAndActivate();

      remoteConfig.onConfigUpdated.listen((event) async {
        debugPrint('🔄 RC updated!');
        await remoteConfig.activate();
        _checkAndPromptForUpdate(remoteConfig);
      });

      // 🚀 INITIAL CHECK
      _checkAndPromptForUpdate(remoteConfig);

    } catch (e) {
      debugPrint("❌ Update check failed: $e");
    }
  }

  static Future<void> _checkAndPromptForUpdate(FirebaseRemoteConfig remoteConfig) async {
    final int minRequiredBuild = remoteConfig.getInt('min_required_version');
    final bool forceUpdate = remoteConfig.getBool('force_update'); 

    final PackageInfo info = await PackageInfo.fromPlatform();
    final int currentBuild = int.parse(info.buildNumber);

    debugPrint(
      "📱 Build: $currentBuild | ☁️ Min Required: $minRequiredBuild | 🚨 Force: $forceUpdate",
    );

    if (currentBuild < minRequiredBuild) {
      await _handleUpdate(forceUpdate);
    }
  }

  static Future<void> _handleUpdate(bool forceUpdate) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {

        // FORCE UPDATE (BLOCK USER)
        if (forceUpdate && updateInfo.immediateUpdateAllowed) {
          debugPrint("🚨 Immediate update triggered");
          await InAppUpdate.performImmediateUpdate();
          return;
        }

        // FLEXIBLE UPDATE (NON-BLOCKING)
        if (updateInfo.flexibleUpdateAllowed) {
          debugPrint("⚡ Flexible update triggered");
          await InAppUpdate.startFlexibleUpdate();
          _showUpdateSnackbar();
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ In-app update failed: $e");
    }
  }

  static void _showUpdateSnackbar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = globalNavigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'A new update is ready to install.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            duration: const Duration(days: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'RESTART',
              textColor: Colors.blueAccent,
              onPressed: () async {
                await InAppUpdate.completeFlexibleUpdate();
              },
            ),
          ),
        );
      }
    });
  }
}