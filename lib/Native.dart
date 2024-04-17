import 'package:arrange_windows/models/ScreenInfo.dart';
import 'package:arrange_windows/models/WindowInfo.dart';
import 'package:arrange_windows/utils.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'models/AppInfo.dart';

class Native {
  static const _channel = MethodChannel('com.tenolife.arrangeWindows/channel');
  static final instance = Native._();
  final log = Logger('Native');

  Native._();

  Future<bool> checkPermissions() async {
    return await _channel.invokeMethod('requestPermissions');
  }

  Future<bool> startSelecting() async {
    return await _channel.invokeMethod('startSelecting');
  }

  Future<bool> endSelecting() async {
    return await _channel.invokeMethod('endSelecting');
  }

  Future<WindowInfo?> get currentWindow async {
    final Map<String, dynamic>? data =
        (await _channel.invokeMethod<Map>('currentWindow'))?.cast();
    return data != null ? WindowInfo.fromJson(data) : null;
  }

  Future<List<ScreenInfo>> get allScreens async {
    final infos = await _channel.invokeMethod<List<Object?>>('screenInfos');
    return infos?.map((e) {
          final Map<String, dynamic> map = (e as Map).cast();
          return ScreenInfo.fromJson(map);
        }).toList(growable: false) ??
        const [];
  }

  Future<List<WindowInfo>> getAllWindows(List<ScreenInfo> screens) async {
    final infos = await _channel.invokeMethod<List<Object?>>('allWindows');
    // There are many windows of a same process Id, and alpha is just an indicator to determine
    // if window is visible or not
    // If the window is onScreen, then we get it and ignore the rest
    // If it is the fullscreen one, take it.
    // Take the largest one.
    final Map<int, WindowInfo> processWindow = {};
    for (final info in infos ?? []) {
      final Map<String, dynamic> map = (info as Map).cast();
      final window = WindowInfo.fromJson(map);
      if (window.alpha == 0.0 || window.height < 25.0) {
        continue;
      }

      final screen = findScreenContains(screens, window);

      if (window.onScreen == true) {
        processWindow[window.processId] =
            window.copyWith(fullScreen: screen.isFullscreen(window));
        continue;
      }

      if (screen.isFullscreen(window)) {
        processWindow[window.processId] = window.copyWith(fullScreen: true);
        continue;
      }
      final candidate = processWindow[window.processId];
      if (candidate == null ||
          (!candidate.fullScreen &&
              candidate.onScreen != true &&
              window.rect.area > candidate.rect.area)) {
        processWindow[window.processId] = window;
        // print(window);
      }
    }
    return processWindow.values.toList(growable: false);
  }

  Future<Rect?> setWindowFrame(WindowInfo? window, Rect rect) async {
    if (window == null) {
      return null;
    }
    final data = window.toJson();
    data['x'] = rect.left;
    data['y'] = rect.top;
    data['width'] = rect.width;
    data['height'] = rect.height;
    final Map<String, dynamic>? result =
        (await _channel.invokeMethod<Map>('setWindowFrame', data))?.cast();
    if (result != null) {
      return Rect.fromLTWH(
          result['x'], result['y'], result['width'], result['height']);
    }
    return null;
  }

  Future<int?> launchApp(AppInfo app) async {
    return await _channel.invokeMethod(
      'launchApp',
      {
        'bundleURL': app.path,
        'bundleIdentifier': app.bundleIdentifier,
        'name': app.name
      },
    );
  }

  Future<void> toggleFullscreen(WindowInfo window) async {
    await _channel.invokeMethod('toggleFullscreen', window.toJson());
    log.info('Attempted to toggle fullscreen of ${window.name}');
  }

  Future<WindowInfo?> refreshWindow(WindowInfo windowInfo) async {
    final Map<String, dynamic>? result =
        (await _channel.invokeMethod<Map>('refreshWindow', windowInfo.toJson()))
            ?.cast();
    if (result != null) {
      return WindowInfo.fromJson(result);
    }
    return null;
  }
}
