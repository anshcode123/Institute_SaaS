import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/student_portal_providers.dart';

class StudentLeavingQrScreen extends ConsumerWidget {
  const StudentLeavingQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCodes = ref.watch(_qrCodesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Leaving QR')),
      body: asyncCodes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
            message: 'Failed to load QR',
            onRetry: () => ref.invalidate(_qrCodesProvider)),
        data: (codes) => Center(
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
                        data: codes.leavingQr ?? '',
                        version: QrVersions.auto,
                        size: 260),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                    'Show this code to your teacher when you leave the institute.',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _qrCodesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(studentPortalRepositoryProvider).getMyQrCodes();
});
