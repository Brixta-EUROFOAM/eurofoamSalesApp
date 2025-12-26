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
          minimumFetchInterval: Duration.zero, // DEV
          // minimumFetchInterval: const Duration(hours: 1), // PROD
        ),
      );

      // SAFE DEFAULT (never lock users if RC fails)
      await remoteConfig.setDefaults({
        'min_required_version': 1,
      });

      await remoteConfig.fetchAndActivate();

      // 🔑 IMPORTANT: This is a BUILD NUMBER
      final int minRequiredBuild =
          remoteConfig.getInt('min_required_version');

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
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 🔒 cannot dismiss
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // 🔒 block back button
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
