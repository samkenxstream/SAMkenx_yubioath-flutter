import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../models.dart';
import '../state.dart';
import 'account_list.dart';

class OathScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const OathScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            node.focusInDirection(TraversalDirection.down);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(builder: (context) {
          return TextFormField(
            initialValue: ref.read(searchProvider),
            decoration: const InputDecoration(
              hintText: 'Search...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              ref.read(searchProvider.notifier).setFilter(value);
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              Focus.of(context).focusInDirection(TraversalDirection.down);
            },
          );
        }),
      ),
      child: ref.watch(oathStateProvider(deviceData.node.path)).when(
            loading: () => const AppLoadingScreen(),
            error: (error, _) => AppFailureScreen('$error'),
            data: (oathState) {
              if (oathState.locked) {
                return ListView(
                  children: [
                    _UnlockForm(
                      keystore: oathState.keystore,
                      onSubmit: (password, remember) async {
                        final result = await ref
                            .read(oathStateProvider(deviceData.node.path)
                                .notifier)
                            .unlock(password, remember: remember);
                        if (!result.first) {
                          showMessage(context, 'Wrong password');
                        } else if (remember && !result.second) {
                          showMessage(context, 'Failed to remember password');
                        }
                      },
                    ),
                  ],
                );
              } else {
                final accounts =
                    ref.watch(credentialListProvider(deviceData.node.path));
                if (accounts == null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                return AccountList(
                  deviceData,
                  ref.watch(filteredCredentialsProvider(accounts)),
                  ref.watch(favoritesProvider),
                );
              }
            },
          ),
    );
  }
}

class _UnlockForm extends StatefulWidget {
  final KeystoreState keystore;
  final Function(String, bool) onSubmit;
  const _UnlockForm({Key? key, required this.keystore, required this.onSubmit})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _UnlockFormState();
}

class _UnlockFormState extends State<_UnlockForm> {
  // TODO: Use a TextEditingController so we can clear it on wrong entry
  String _password = '';
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    final keystoreFailed = widget.keystore == KeystoreState.failed;
    return Column(
      //mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Unlock YubiKey',
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              const Text(
                'Enter the password for your YubiKey. If you don\'t know your password, you\'ll need to reset the YubiKey.',
              ),
              TextField(
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
                onSubmitted: (value) {
                  widget.onSubmit(value, _remember);
                },
              ),
            ],
          ),
        ),
        CheckboxListTile(
          title: const Text('Remember password'),
          subtitle: Text(keystoreFailed
              ? 'The OS keychain is not available.'
              : 'Uses the OS keychain to protect access to this YubiKey.'),
          controlAffinity: ListTileControlAffinity.leading,
          value: _remember,
          onChanged: keystoreFailed
              ? null
              : (value) {
                  setState(() {
                    _remember = value ?? false;
                  });
                },
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            child: const Text('Unlock'),
            onPressed: () {
              widget.onSubmit(_password, _remember);
            },
          ),
        ),
      ],
    );
  }
}
