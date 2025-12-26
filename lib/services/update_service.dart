import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // CONFIG: Store links
  static const String _androidUrl =
      "https://play.google.com/store/apps/details?id=com.salesmanapp.best";
  static const String _iosUrl =
      "https://apps.apple.com/app/idYOUR_APP_ID";

  static Future<void> checkVersion(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Remote Config settings
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          // For real-time updates, minimumFetchInterval becomes less critical after the initial fetch.
          // You can keep Duration.zero for development, or a longer duration for production
          // as the listener will bypass it for immediate updates.
          minimumFetchInterval: Duration.zero, 
        ),
      );

      // SAFE DEFAULT (never lock users if RC fails)
      await remoteConfig.setDefaults({
        'min_required_version': 1,
      });

      // --- Initial fetch and activate ---
      // This is still good to do when the app starts to get the latest config immediately.
      await remoteConfig.fetchAndActivate();

      // --- Add the real-time listener ---
      // This listener will be invoked whenever a new config version is published on the server.
      remoteConfig.onConfigUpdated.listen((event) async {
        debugPrint('Remote Config updated in real-time!');
        // Activate the newly fetched config values
        await remoteConfig.activate();
        debugPrint('Activated new Remote Config values.');

        // Now, re-check the version with the newly activated config
        _checkAndPromptForUpdate(context, remoteConfig);
      }, onError: (error) {
        debugPrint('Error listening for Remote Config updates: $error');
      });

      // Also perform an initial check based on the config fetched at startup
      _checkAndPromptForUpdate(context, remoteConfig);

    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static Future<void> _checkAndPromptForUpdate(BuildContext context, FirebaseRemoteConfig remoteConfig) async {
    final int minRequiredBuild = remoteConfig.getInt('min_required_version');

    final PackageInfo info = await PackageInfo.fromPlatform();
    final int currentBuild = int.parse(info.buildNumber);

    debugPrint(
      "📱 App Build: $currentBuild | ☁️ Min Required Build: $minRequiredBuild",
    );

    if (currentBuild < minRequiredBuild) {
      if (context.mounted) {
        _showUpdateDialog(context);
      }
    }
  }

 static void _showUpdateDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // 🔒 cannot tap outside
    builder: (context) => PopScope(
      canPop: false, // 🔒 blocks system back & predictive back
      child: AlertDialog(
        title: const Text("Update Required"),
        content: const Text(
          "A new version of the app is available. Please update to continue using the app.",
        ),
        actions: [
          ElevatedButton(
            onPressed: _launchStore,
            child: const Text("Update Now"),
          ),
        ],
      ),
    ),
  );
}


  static void _launchStore() async {
    final url = Uri.parse(
      Platform.isAndroid ? _androidUrl : _iosUrl,
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}