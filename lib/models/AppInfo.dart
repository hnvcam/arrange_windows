import 'dart:ui';

import 'package:arrange_windows/models/WindowInfo.dart';
import 'package:isar/isar.dart';

part 'generated/AppInfo.g.dart';

@embedded
class AppInfo {
  String? name;
  String? bundleIdentifier;
  String? path;
  bool? fullScreen;

  double? left;
  double? top;
  double? width;
  double? height;

  @ignore
  Rect get rect => Rect.fromLTWH(left!, top!, width!, height!);

  static AppInfo from(WindowInfo window) {
    final app = AppInfo();
    app.name = window.name;
    app.bundleIdentifier = window.bundleIdentifier;
    app.path = window.bundleURL;
    app.fullScreen = window.fullScreen;
    app.left = window.rect.left;
    app.top = window.rect.top;
    app.width = window.rect.width;
    app.height = window.rect.height;
    return app;
  }

  @override
  String toString() =>
      'AppInfo(name: $name, bundleIdentifier: $bundleIdentifier, path: $path, fullScreen: $fullScreen, left: $left, top: $top, width: $width, height: $height)';
}
