import 'package:arrange_windows/models/Profile.dart';
import 'package:flutter/material.dart';

import '../Native.dart';
import '../models/WindowInfo.dart';

class CloseUnrelatedWindowsDialog extends StatefulWidget {
  final Profile profile;
  const CloseUnrelatedWindowsDialog({super.key, required this.profile});

  @override
  State<CloseUnrelatedWindowsDialog> createState() =>
      _CloseUnrelatedWindowsDialogState();
}

class _CloseUnrelatedWindowsDialogState
    extends State<CloseUnrelatedWindowsDialog> {
  Iterable<WindowInfo> _terminates = [];

  @override
  void initState() {
    super.initState();
    _asyncInit();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AlertDialog(
      title: const Text('Close unrelated windows?'),
      content: SizedBox(
        width: size.height * 0.5,
        height: size.width * 0.5,
        child: _terminates.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: _terminates.length,
                itemBuilder: (BuildContext context, int index) {
                  final window = _terminates.elementAt(index);
                  return ListTile(
                    title: Text(window.name),
                    subtitle:
                        Text(window.bundleIdentifier ?? window.bundleURL ?? ""),
                  );
                },
              )
            : const SizedBox(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _terminates),
          child: const Text('Yes'),
        )
      ],
    );
  }

  Future<void> _asyncInit() async {
    final Set<String> appKeys = {};
    for (final app in widget.profile.apps) {
      if (app.bundleIdentifier?.isNotEmpty == true) {
        appKeys.add(app.bundleIdentifier!);
      }
      if (app.path?.isNotEmpty == true) {
        appKeys.add(app.path!);
      }
    }

    if (appKeys.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final screens = await Native.instance.allScreens;
    final windows = await Native.instance.getAllWindows(screens);
    // find redundant windows to terminate
    _terminates = windows.where((element) =>
        !appKeys.contains(element.bundleIdentifier) &&
        !appKeys.contains(element.bundleURL));
    if (_terminates.isEmpty && mounted) {
      Navigator.pop(context, null);
      return;
    }

    setState(() {});
  }
}
