import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/WindowInfo.freezed.dart';
part 'generated/WindowInfo.g.dart';

@freezed
class WindowInfo with _$WindowInfo {
  const WindowInfo._();

  factory WindowInfo({
    @Default("Unknown") String name,
    required int processId,
    required int windowNumber,
    required double x,
    required double y,
    required double width,
    required double height,
    required int sharingState,
    required int layer,
    required double alpha,
    String? bundleIdentifier,
    String? bundleURL,
    bool? onScreen,
    bool? hidden,
    bool? active,
    @Default(false) bool fullScreen,
  }) = _WindowInfo;

  factory WindowInfo.fromJson(Map<String, dynamic> json) =>
      _$WindowInfoFromJson(json);

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}
