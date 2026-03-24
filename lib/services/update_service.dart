// lib/services/update_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {

  static Future<void> checkVersion() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );

      await remoteConfig.setDefaults({
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

  static Future<void> _checkAndPromptForUpdate(
    FirebaseRemoteConfig remoteConfig,
  ) async {
    final int minRequiredBuild =
        remoteConfig.getInt('min_required_version');

    final bool forceUpdate =
        remoteConfig.getBool('force_update'); 

    final PackageInfo info = await PackageInfo.fromPlatform();
    final int currentBuild = int.parse(info.buildNumber);

    debugPrint(
      "📱 Build: $currentBuild | ☁️ Min: $minRequiredBuild | 🚨 Force: $forceUpdate",
    );

    if (currentBuild < minRequiredBuild) {
      await _handleUpdate(forceUpdate);
    }
  }

  static Future<void> _handleUpdate(bool forceUpdate) async {
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {

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
          await InAppUpdate.completeFlexibleUpdate();
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ In-app update failed: $e");
    }
    debugPrint("⚠️ Update available but could not trigger UI");
  }
}