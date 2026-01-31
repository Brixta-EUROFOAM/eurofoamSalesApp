import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'package:qr_flutter/qr_flutter.dart';

class MasonQrDialog extends StatelessWidget {
  final String masonName;
  final String userId;
  final String password;
  final String qrData;

  const MasonQrDialog({
    super.key,
    required this.masonName,
    required this.userId,
    required this.password,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 520, // 👈 prevents overflow
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Mason Login Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                masonName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // ✅ QR
              Container(
                padding: const EdgeInsets.all(20), // TRUE quiet zone
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData,
                  size: 260, // 👈 BIGGER = BETTER
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.H, // 🔥 CRITICAL
                ),
              ),

              const SizedBox(height: 20),

              _infoTile(context, "User ID", userId),
              const SizedBox(height: 10),
              _infoTile(context, "Password", password),

              const SizedBox(height: 20),

              Text(
                "Scan QR or use credentials to login",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$label copied"),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
