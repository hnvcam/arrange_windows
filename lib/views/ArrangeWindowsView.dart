import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/components/ProfileActions.dart';
import 'package:arrange_windows/components/ScreenWindowVisual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../components/QuickActions.dart';
import '../components/WindowExplorer.dart';

class ArrangeWindowsView extends StatelessWidget {
  final int maxRetries;
  final Duration retryDelay;
  const ArrangeWindowsView(
      {super.key,
      this.maxRetries = 5,
      this.retryDelay = const Duration(milliseconds: 500)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Row(
        children: [
          const QuickActions(),
          Expanded(
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                  dividerPainter: DividerPainters.grooved1(
                      color: Colors.indigo[100]!,
                      highlightedColor: Colors.indigo[900]!)),
              child: MultiSplitView(
                initialAreas: [Area(weight: 0.8), Area(minimalSize: 200.0)],
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ScreenWindowVisual(),
                  ),
                  Container(
                      color: theme.colorScheme.surfaceVariant,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocBuilder<ExecutorBloc, ExecutorState>(
                              builder: (context, state) {
                            if (!state.isSelecting) {
                              return TextButton.icon(
                                  onPressed: () => ExecutorBloc.read(context)
                                      .add(const RequestStopCapturing()),
                                  icon: const Icon(Icons.stop),
                                  label: const Text("Stop capturing"));
                            }
                            return TextButton.icon(
                                onPressed: () => ExecutorBloc.read(context)
                                    .add(const RequestCaptureNewWindow()),
                                icon: const Icon(Icons.ads_click),
                                label: const Text("Capture new window"));
                          }),
                          TextButton.icon(
                            onPressed: () => ExecutorBloc.read(context)
                                .add(const RequestCaptureAllWindows()),
                            icon: const Icon(Icons.refresh),
                            label: const Text("Capture all windows"),
                          ),
                          const Gap(16.0),
                          const Expanded(child: WindowExplorer()),
                          const Gap(16.0),
                          const ProfileActions()
                        ],
                      ))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
