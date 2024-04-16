import 'dart:math';
import 'dart:ui';
import 'package:arrange_windows/models/WindowInfo.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/ScreenInfo.freezed.dart';
part 'generated/ScreenInfo.g.dart';

@freezed
class ScreenInfo with _$ScreenInfo {
  const ScreenInfo._();

  factory ScreenInfo({
    @Default("Unknown") String name,
    required double width,
    required double height,
    required double x,
    required double y,
    required double visibleX,
    required double visibleY,
    required double visibleWidth,
    required double visibleHeight,
    required double safeTop,
    required double safeLeft,
    required double safeBottom,
    required double safeRight,
  }) = _ScreenInfo;

  factory ScreenInfo.fromJson(Map<String, dynamic> json) =>
      _$ScreenInfoFromJson(json);

  Rect get rect => Rect.fromLTWH(x, max(0, y), width, height);

  Rect get visibleRect =>
      Rect.fromLTWH(visibleX, visibleY, visibleWidth, visibleHeight);

  Rect normalizeToGlobal(Rect localRect) => Rect.fromLTWH(
        max(visibleX, localRect.left),
        max(visibleY, localRect.top),
        min(visibleWidth, localRect.width),
        min(visibleHeight, localRect.height),
      );

  Rect toLocal(Rect globalRect) => Rect.fromLTWH(
        globalRect.left - x,
        globalRect.top - max(0, y),
        globalRect.width,
        globalRect.height,
      );

  bool isFullscreen(WindowInfo window) {
    return window.width == width &&
        window.height == height &&
        window.x == x &&
        window.y == max(0, y);
  }
}
