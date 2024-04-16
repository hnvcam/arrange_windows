import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ExecutorBloc.dart';
import '../models/ScreenInfo.dart';
import '../models/WindowInfo.dart';
import '../utils.dart';

class ScreenWindowVisual extends StatelessWidget {
  final double borderWidth;
  const ScreenWindowVisual({
    super.key,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ExecutorBloc, ExecutorState>(builder: (context, state) {
      final screenMap = <ScreenInfo, List<WindowInfo>>{};
      for (var window in state.windows) {
        final screen = findScreenContains(state.screens, window);
        screenMap[screen] = (screenMap[screen] ?? [])..add(window);
      }

      final totalScreen = state.screens.fold(
          Rect.zero,
          (previous, screen) => previous.expandToInclude(Rect.fromLTWH(
              screen.x,
              screen.y,
              screen.width + 2 * borderWidth,
              screen.height + 2 * borderWidth)));

      final totalRatio = totalScreen.width / totalScreen.height;

      return LayoutBuilder(builder: (context, constraints) {
        final displayWidth =
            min(constraints.maxWidth, constraints.maxHeight * totalRatio);
        final displayHeight =
            min(constraints.maxHeight, constraints.maxWidth / totalRatio);
        final horizontalRatio = displayWidth / totalScreen.width;
        final verticalRatio = displayHeight / totalScreen.height;

        final topOffset = (constraints.maxHeight - displayHeight) / 2;
        final leftOffset = (constraints.maxWidth - displayWidth) / 2;

        return Stack(
          children: [
            for (var screen in state.screens)
              Positioned(
                  left: leftOffset +
                      (screen.x - totalScreen.left) * horizontalRatio,
                  top: topOffset + (screen.y - totalScreen.top) * verticalRatio,
                  width: (screen.width + 2 * borderWidth) * horizontalRatio,
                  height: (screen.height + 2 * borderWidth) * verticalRatio,
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.black, width: borderWidth)),
                      child: Stack(
                        children: [
                          Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                  child: Text(screen.name,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                      )))),
                          for (var window in (screenMap[screen] ?? const []))
                            Builder(builder: (context) {
                              final localRect = screen.toLocal(window.rect);

                              return Positioned(
                                  left: localRect.left * horizontalRatio,
                                  top: localRect.top * verticalRatio,
                                  width: localRect.width * horizontalRatio,
                                  height: localRect.height * verticalRatio,
                                  child: InkWell(
                                    onTap: () => ExecutorBloc.read(context)
                                        .add(RequestSelectWindow(window)),
                                    child: Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme.primaryContainer
                                                .withAlpha(window ==
                                                        state.selectedWindow
                                                    ? 200
                                                    : 100),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(8.0))),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Flexible(
                                              child: Container(
                                                color: theme
                                                    .colorScheme.secondary
                                                    .withAlpha(window ==
                                                            state.selectedWindow
                                                        ? 255
                                                        : 100),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                                  child: Text(
                                                    window.name,
                                                    style: theme
                                                        .textTheme.labelMedium
                                                        ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSecondary),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                    '${localRect.width} x ${localRect.height}',
                                                    style: theme
                                                        .textTheme.bodySmall),
                                              ),
                                            )
                                          ],
                                        )),
                                  ));
                            })
                        ],
                      ))),
          ],
        );
      });
    });
  }
}
