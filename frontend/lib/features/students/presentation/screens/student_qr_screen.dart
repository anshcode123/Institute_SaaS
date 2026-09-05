import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Displays the student's opaque QR token as a scannable code. The token
/// itself carries no student data - it's just a lookup key the backend
/// resolves server-side (see backend/src/utils/qr-token.js).
class StudentQrScreen extends StatelessWidget {
  const StudentQrScreen({
    super.key,
    required this.qrCode,
    required this.studentName,
    required this.studentCode,
  });

  final String qrCode;
  final String studentName;
  final String studentCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student QR Code')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: QrImageView(
                    data: qrCode,
                    version: QrVersions.auto,
                    size: 260,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(studentName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(studentCode, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Text(
                'Show this code to your teacher to be marked present.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
