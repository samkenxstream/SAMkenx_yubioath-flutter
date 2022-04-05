import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteFingerprintDialog extends ConsumerWidget {
  final DevicePath devicePath;
  final Fingerprint fingerprint;
  const DeleteFingerprintDialog(this.devicePath, this.fingerprint, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop(false);
    });

    final label = fingerprint.label;

    return ResponsiveDialog(
      title: const Text('Delete fingerprint'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This will delete the fingerprint from your YubiKey.'),
          Text('Fingerprint: $label'),
        ]
            .map((e) => Padding(
                  child: e,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(fingerprintProvider(devicePath).notifier)
                .deleteFingerprint(fingerprint);
            Navigator.of(context).pop(true);
            showMessage(context, 'Fingerprint deleted');
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}