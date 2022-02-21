import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../state.dart';

class ManagePasswordDialog extends ConsumerStatefulWidget {
  final DeviceNode device;
  const ManagePasswordDialog(this.device, {Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePasswordDialogState();
}

class _ManagePasswordDialogState extends ConsumerState<ManagePasswordDialog> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _currentIsWrong = false;

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    final state = ref.watch(oathStateProvider(widget.device.path));
    final hasKey = state?.hasKey ?? false;
    final remembered = state?.remembered ?? false;

    return AlertDialog(
      title: const Text('Manage password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasKey)
            Column(
              children: [
                if (remembered)
                  // TODO: This is temporary, to be able to forget a password.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'You password is remembered by the app.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await ref
                                    .read(oathStateProvider(widget.device.path)
                                        .notifier)
                                    .forgetPassword();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password forgotten'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('Forget'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Text(
                    'Enter your current password to change it. If you don\'t know your password, you\'ll need to reset the YubiKey, then create a new password.'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: 'Current',
                            errorText:
                                _currentIsWrong ? 'Wrong password' : null),
                        onChanged: (value) {
                          setState(() {
                            _currentPassword = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 8.0,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            child: const Text('Remove'),
                            onPressed: _currentPassword.isNotEmpty
                                ? () async {
                                    final result = await ref
                                        .read(oathStateProvider(
                                                widget.device.path)
                                            .notifier)
                                        .unsetPassword(_currentPassword);
                                    if (result) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Password removed'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        _currentIsWrong = true;
                                      });
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16.0,
                ),
              ],
            ),
          const Text(
              'Enter your new password. A password may contain letters, numbers and other characters.'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: !hasKey,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: (value) {
                    setState(() {
                      _newPassword = value;
                    });
                  },
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _confirmPassword = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _newPassword.isNotEmpty &&
                  _newPassword == _confirmPassword &&
                  (!hasKey || _currentPassword.isNotEmpty)
              ? () async {
                  final result = await ref
                      .read(oathStateProvider(widget.device.path).notifier)
                      .setPassword(_currentPassword, _newPassword);
                  if (result) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password set'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    setState(() {
                      _currentIsWrong = true;
                    });
                  }
                }
              : null,
          child: const Text('Save'),
        )
      ],
    );
  }
}
