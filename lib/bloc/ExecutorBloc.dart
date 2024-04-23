import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../Native.dart';
import '../models/Profile.dart';
import '../models/ScreenInfo.dart';
import '../models/WindowInfo.dart';
import '../utils.dart';

part 'ExecutorEvent.dart';
part 'ExecutorState.dart';
part 'ExecutorType.dart';

class ExecutorBloc extends Bloc<ExecutorEvent, ExecutorState> {
  final log = Logger('ExecutorBloc');

  static ExecutorBloc read(BuildContext context) =>
      context.read<ExecutorBloc>();

  final int maxRetries;
  final double resizeStep;

  ExecutorBloc(
      {this.maxRetries = 5,
      this.resizeStep = 10,
      ExecutorState initial = ExecutorState.empty})
      : super(initial) {
    on<_Initializing>(_onInitializing);
    on<RequestLoadProfileWindows>(_loadProfileWindows);
    on<RequestArrangeSelectedWindow>(_arrangeSelectedWindow);
    on<RequestSelectWindow>(_selectWindow);
    on<RequestRemoveWindow>(_removeWindow);
    on<RequestCaptureNewWindow>(_startCapturingNewWindow);
    on<RequestStopCapturing>(_stopCapturing);
    on<RequestCaptureAllWindows>(_captureAllWindows);
    on<RequestCloseAllWindows>(_closeAllWindows);

    add(const _Initializing());
  }

  FutureOr<void> _onInitializing(
      _Initializing event, Emitter<ExecutorState> emit) async {
    final screens = await Native.instance.allScreens;
    final windows = await Native.instance.getAllWindows(screens);
    emit(state.copyWith(screens: screens, windows: windows));
  }

  FutureOr<void> _loadProfileWindows(
      RequestLoadProfileWindows event, Emitter<ExecutorState> emit) async {
    final windowMaps = await _getCurrentWindowMaps();
    // find missing windows to launch
    final launchWindows = event.profile.apps.where((element) =>
        !windowMaps.$1.containsKey(element.bundleIdentifier) &&
        !windowMaps.$2.containsKey(element.path));
    final failedApps = [];

    for (var app in launchWindows) {
      final result = await Native.instance.launchApp(app);
      if (result == null) {
        failedApps.add(app);
      }
    }
    log.info("Unable to launch apps: $failedApps");

    final remains = List.of(event.profile.apps);
    int retryCount = 0;
    while (remains.isNotEmpty && retryCount < maxRetries) {
      final updatedMaps = await _getCurrentWindowMaps();

      for (var app in List.of(remains)) {
        final window =
            updatedMaps.$1[app.bundleIdentifier] ?? updatedMaps.$2[app.path];
        if (window == null) {
          continue;
        }
        if ((app.fullScreen == true && window.fullScreen == false) ||
            (app.fullScreen != true && window.fullScreen == true)) {
          await Native.instance.toggleFullscreen(window);
          log.info(
              '${app.name} current=${window.fullScreen} target=${app.fullScreen}');
          // we don't process any further, let the next loop get the latest state of windows
          continue;
        }

        // print('$retryCount ==> $app');

        if (app.fullScreen != true &&
            (await Native.instance.setWindowFrame(window, app.rect) == null)) {
          continue;
        }
        remains.remove(app);
      }
      // wait for every things settle before retry
      await Future.delayed(const Duration(seconds: 1));
      retryCount++;
    }

    log.info("Unable to set position & size for apps: $remains");
  }

  Future<(Map<String, WindowInfo> bundleIdMap, Map<String, WindowInfo> pathMap)>
      _getCurrentWindowMaps() async {
    final windows = await Native.instance.getAllWindows(state.screens);
    final bundleIdMap = <String, WindowInfo>{};
    final pathMap = <String, WindowInfo>{};
    for (var w in windows) {
      if (w.bundleIdentifier?.isNotEmpty == true) {
        bundleIdMap[w.bundleIdentifier!] = w;
      }
      if (w.bundleURL?.isNotEmpty == true) {
        pathMap[w.bundleURL!] = w;
      }
    }
    return (bundleIdMap, pathMap);
  }

  FutureOr<void> _arrangeSelectedWindow(
      RequestArrangeSelectedWindow event, Emitter<ExecutorState> emit) async {
    assert(state.selectedWindow != null);
    final screen = findScreenContains(state.screens, state.selectedWindow!);

    late Rect rect;
    final visibleRect = screen.visibleRect;

    switch (event.arrangement) {
      case Arrangement.prevDisplay:
        final prevScreen = _findPrevScreen(screen);
        rect = prevScreen.visibleRect;
        break;
      case Arrangement.nextDisplay:
        final nextScreen = _findPrevScreen(screen, true);
        rect = nextScreen.visibleRect;
        break;
      case Arrangement.almostMaximize:
        rect = visibleRect;
        break;
      case Arrangement.makeLarger:
        final left =
            max(visibleRect.left, state.selectedWindow!.x - resizeStep);
        final top = max(visibleRect.top, state.selectedWindow!.y - resizeStep);
        rect = Rect.fromLTWH(
            left,
            top,
            min(visibleRect.width - left + visibleRect.left,
                state.selectedWindow!.width + resizeStep * 2),
            min(visibleRect.height - top + visibleRect.top,
                state.selectedWindow!.height + resizeStep * 2));
        break;
      case Arrangement.makeSmaller:
        final width = max(100.0, state.selectedWindow!.width - resizeStep * 2);
        final height =
            max(100.0, state.selectedWindow!.height - resizeStep * 2);
        rect = Rect.fromLTWH(
          min(visibleRect.left + visibleRect.width - width,
              state.selectedWindow!.x + resizeStep),
          min(visibleRect.top + visibleRect.height - height,
              state.selectedWindow!.y + resizeStep),
          width,
          height,
        );
        break;
      case Arrangement.leftHalf:
        rect = visibleRect.copyWith(width: visibleRect.width / 2);
        break;
      case Arrangement.rightHalf:
        rect = visibleRect.copyWith(
            left: visibleRect.left + visibleRect.width / 2,
            width: visibleRect.width / 2);
        break;
      case Arrangement.topHalf:
        rect = visibleRect.copyWith(height: visibleRect.height / 2);
        break;
      case Arrangement.bottomHalf:
        rect = visibleRect.copyWith(
            top: visibleRect.top + visibleRect.height / 2,
            height: visibleRect.height / 2);
        break;
      case Arrangement.firstThird:
        rect = visibleRect.copyWith(width: visibleRect.width / 3);
        break;
      case Arrangement.lastThird:
        rect = visibleRect.copyWith(
            left: visibleRect.left + visibleRect.width * 2 / 3,
            width: visibleRect.width / 3);
        break;
      case Arrangement.firstTwoThirds:
        rect = visibleRect.copyWith(width: visibleRect.width * 2 / 3);
        break;
      case Arrangement.lastTwoThirds:
        rect = visibleRect.copyWith(
            left: visibleRect.left + visibleRect.width / 3,
            width: visibleRect.width * 2 / 3);
        break;
      default:
    }

    if (state.selectedWindow!.fullScreen) {
      await Native.instance.toggleFullscreen(state.selectedWindow!);
    }

    final result =
        await Native.instance.setWindowFrame(state.selectedWindow!, rect);
    if (result != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      final latestWindowInfo =
          await Native.instance.refreshWindow(state.selectedWindow!);
      if (latestWindowInfo != null) {
        emit(state.copyWith(
            windows: List.of(state.windows)
              ..removeWhere((element) =>
                  element.windowNumber == latestWindowInfo.windowNumber)
              ..add(latestWindowInfo),
            selectedWindow: latestWindowInfo));
      }
    } else {
      log.severe('Unable to arrange selected window');
    }
  }

  _findPrevScreen(ScreenInfo screen, [bool reserved = false]) {
    ScreenInfo? prevScreen;
    final list = reserved ? state.screens.reversed : state.screens;
    for (var s in list) {
      if (s.rect == screen.rect) {
        break;
      }
      prevScreen = s;
    }
    return prevScreen ?? state.screens.last;
  }

  FutureOr<void> _selectWindow(
      RequestSelectWindow event, Emitter<ExecutorState> emit) {
    emit(state.copyWith(selectedWindow: event.window));
  }

  FutureOr<void> _removeWindow(
      RequestRemoveWindow event, Emitter<ExecutorState> emit) {
    emit(state.copyWith(
        windows: List.of(state.windows)..remove(event.window),
        selectedWindow:
            (state.selectedWindow?.windowNumber == event.window.windowNumber)
                ? null
                : state.selectedWindow));
  }

  FutureOr<void> _startCapturingNewWindow(
      RequestCaptureNewWindow event, Emitter<ExecutorState> emit) async {
    await Native.instance.startSelecting();
    emit(state.copyWith(isSelecting: true));
    _pollForWindow(emit);
  }

  Future<void> _pollForWindow(Emitter<ExecutorState> emit) async {
    while (state.isSelecting) {
      await Future.delayed(const Duration(seconds: 1));
      final selection = await Native.instance.currentWindow;
      if (selection != null) {
        emit(state.copyWith(
            isSelecting: false,
            selectedWindow: selection,
            windows: List.of(state.windows)
              ..removeWhere(
                  (element) => element.windowNumber == selection.windowNumber)
              ..add(selection)));
        break;
      }
    }
  }

  FutureOr<void> _stopCapturing(
      RequestStopCapturing event, Emitter<ExecutorState> emit) async {
    await Native.instance.endSelecting();
    emit(state.copyWith(isSelecting: false));
  }

  FutureOr<void> _captureAllWindows(
      RequestCaptureAllWindows event, Emitter<ExecutorState> emit) async {
    final windows = await Native.instance.getAllWindows(state.screens);
    emit(state.copyWith(
        windows: windows,
        selectedWindow: windows.firstWhereOrNull((element) =>
            element.windowNumber == state.selectedWindow?.windowNumber)));
  }

  FutureOr<void> _closeAllWindows(
      RequestCloseAllWindows event, Emitter<ExecutorState> emit) async {
    // in flutter, we have rules to filter all invisible windows
    final windows = await Native.instance.getAllWindows(state.screens);
    await Native.instance.closeAllWindows(windows);
  }
}
