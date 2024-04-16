import 'dart:developer';
import 'dart:ui';

import 'package:arrange_windows/models/ScreenInfo.dart';
import 'package:arrange_windows/models/WindowInfo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

ScreenInfo findScreenContains(List<ScreenInfo> screens, WindowInfo window) {
  ScreenInfo? container;
  Rect? intersect;
  for (var screen in screens) {
    if (screen.rect.containsRect(window.rect)) {
      return screen;
    }
    final rect = screen.rect.intersect(window.rect);
    if (intersect == null || rect.area > intersect.area) {
      intersect = rect;
      container = screen;
    }
  }
  return container!;
}

extension RectExtension on Rect {
  bool containsRect(Rect rect) {
    return left <= rect.left &&
        top <= rect.top &&
        right >= rect.right &&
        bottom >= rect.bottom;
  }

  Rect copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return Rect.fromLTWH(
      left ?? this.left,
      top ?? this.top,
      width ?? this.width,
      height ?? this.height,
    );
  }

  double get area => width * height;
}

extension Find<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

void debugLog([List<String>? loggerNames]) {
  if (kReleaseMode) {
    return;
  }
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((event) {
    if (loggerNames != null &&
        event.level < Level.SEVERE &&
        !loggerNames.contains(event.loggerName)) {
      return;
    }
    log(event.message, name: event.loggerName);
  });
}

void debugBloc([List<Type>? filters, bool details = false]) {
  if (kReleaseMode) {
    return;
  }
  Bloc.observer = BlocDebugger(filters, details);
}

class BlocDebugger implements BlocObserver {
  final List<Type>? filters;
  final bool details;

  BlocDebugger(this.filters, this.details);

  bool _showLog(BlocBase<dynamic> bloc) {
    if (filters == null) {
      return true;
    }
    return filters!.contains(bloc.runtimeType);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    // Covered by onTransition
    // print(
    //     'Bloc: ${bloc.runtimeType} got changed: \n\tFrom: ${change.currentState} \n\tTo: ${change.nextState}');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    if (!_showLog(bloc)) return;
    log('closed', name: bloc.runtimeType.toString());
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    if (!_showLog(bloc)) return;
    log('created', name: bloc.runtimeType.toString());
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // TODO: implement onError
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    if (!_showLog(bloc)) return;
    log("Received ${event.runtimeType}", name: bloc.runtimeType.toString());
  }

  @override
  void onTransition(
      Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    if (!details || !_showLog(bloc)) return;
    log('transits:\n\tFrom: ${transition.currentState} \n\tTo: ${transition.nextState} \n\tCaused by: ${transition.event.runtimeType}',
        name: bloc.runtimeType.toString());
  }
}
