import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/WindowInfo.dart';

class WindowExplorer extends StatelessWidget {
  const WindowExplorer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.background,
      child:
          BlocBuilder<ExecutorBloc, ExecutorState>(builder: (context, state) {
        return ListView.builder(
            itemBuilder: (context, index) => _WindowItem(
                  window: state.windows[index],
                  even: index % 2 == 0,
                  onSelect: (window) => ExecutorBloc.read(context)
                      .add(RequestSelectWindow(window)),
                  selected: state.windows[index] == state.selectedWindow,
                  onRemove: (window) => ExecutorBloc.read(context)
                      .add(RequestRemoveWindow(window)),
                ),
            itemCount: state.windows.length);
      }),
    );
  }
}

class _WindowItem extends StatefulWidget {
  final WindowInfo window;
  final bool even;
  final bool selected;
  final void Function(WindowInfo window) onSelect;
  final void Function(WindowInfo windowInfo) onRemove;

  const _WindowItem(
      {required this.window,
      required this.even,
      required this.onSelect,
      required this.selected,
      required this.onRemove});

  @override
  State<_WindowItem> createState() => _WindowItemState();
}

class _WindowItemState extends State<_WindowItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = Uri.parse(widget.window.bundleURL ?? '');

    return AnimatedContainer(
        color: widget.selected
            ? theme.colorScheme.primaryContainer
            : widget.even
                ? theme.colorScheme.primaryContainer.withAlpha(50)
                : theme.colorScheme.inversePrimary.withAlpha(50),
        margin: EdgeInsets.symmetric(
            horizontal: 2.0, vertical: _expanded ? 4.0 : 1.0),
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                  child: TextButton(
                    onPressed: () => widget.onSelect(widget.window),
                    style: const ButtonStyle(
                      alignment: Alignment.centerLeft,
                      padding: MaterialStatePropertyAll(EdgeInsets.zero),
                    ),
                    child: Text(widget.window.name),
                  ),
                )),
                IconButton(
                    onPressed: _toggleExpanded,
                    icon: _expanded
                        ? const Icon(Icons.expand_less)
                        : const Icon(Icons.expand_more)),
              ],
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                      'Path: ${url.path}',
                      style: theme.textTheme.bodySmall,
                    )),
                    IconButton(
                      onPressed: () => widget.onRemove(widget.window),
                      icon: const Icon(Icons.delete),
                      color: theme.colorScheme.error,
                    )
                  ],
                ),
              )
          ],
        ));
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }
}
