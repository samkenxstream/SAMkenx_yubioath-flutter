import 'package:flutter/material.dart';

class ResponsiveDialog extends StatefulWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Function()? onCancel;

  const ResponsiveDialog(
      {super.key,
      required this.child,
      this.title,
      this.actions = const [],
      this.onCancel});

  @override
  State<ResponsiveDialog> createState() => _ResponsiveDialogState();
}

class _ResponsiveDialogState extends State<ResponsiveDialog> {
  final Key _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: ((context, constraints) {
        if (constraints.maxWidth < 540) {
          // Fullscreen
          return Scaffold(
            appBar: AppBar(
              title: widget.title,
              actions: widget.actions,
              leading: CloseButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(key: _childKey, child: widget.child),
            ),
          );
        } else {
          // Dialog
          final cancelText = widget.onCancel == null && widget.actions.isEmpty
              ? 'Close'
              : 'Cancel';
          return AlertDialog(
            title: widget.title,
            scrollable: true,
            content: SizedBox(
              width: 380,
              child: Container(key: _childKey, child: widget.child),
            ),
            actions: [
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
              ),
              ...widget.actions
            ],
          );
        }
      }));
}
