part of 'ExecutorBloc.dart';

class ExecutorState extends Equatable {
  static const empty = ExecutorState();

  final List<ScreenInfo> screens;
  final List<WindowInfo> windows;
  final WindowInfo? selectedWindow;
  final bool isSelecting;

  const ExecutorState(
      {this.screens = const [],
      this.windows = const [],
      this.selectedWindow,
      this.isSelecting = false});

  ExecutorState copyWith({
    List<ScreenInfo>? screens,
    List<WindowInfo>? windows,
    WindowInfo? selectedWindow,
    bool? isSelecting,
  }) {
    return ExecutorState(
      screens: screens ?? this.screens,
      windows: windows ?? this.windows,
      selectedWindow: selectedWindow ?? this.selectedWindow,
      isSelecting: isSelecting ?? this.isSelecting,
    );
  }

  @override
  List<Object?> get props => [screens, windows, selectedWindow, isSelecting];
}
