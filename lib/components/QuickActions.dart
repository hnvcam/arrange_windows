import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:flutter/material.dart';

class QuickActions extends StatefulWidget {
  const QuickActions({
    super.key,
  });

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _toggleExpanded,
            icon: _expanded
                ? const Icon(Icons.arrow_left)
                : const Icon(Icons.arrow_right),
            style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: MaterialStatePropertyAll(Size.zero)),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                        extended: _expanded,
                        onDestinationSelected: _takeAction,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        destinations: [
                          for (var dest in Arrangement.values)
                            NavigationRailDestination(
                              icon: Image.asset(dest.assetPath),
                              label: Text(dest.label),
                            )
                        ],
                        selectedIndex: 0),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _takeAction(int value) {
    final arrangement = Arrangement.values[value];
    final executor = ExecutorBloc.read(context);
    if (executor.state.selectedWindow == null) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('Unable to execute'),
                content: const Text('Please select a window to arrange!'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Okay'))
                ],
              ));
      return;
    }
    ExecutorBloc.read(context).add(RequestArrangeSelectedWindow(arrangement));
  }
}
