part of 'ExecutorBloc.dart';

sealed class ExecutorEvent {
  const ExecutorEvent();
}

class _Initializing extends ExecutorEvent {
  const _Initializing();
}

class RequestLoadProfileWindows extends ExecutorEvent {
  final Profile profile;
  const RequestLoadProfileWindows(this.profile);
}

class RequestArrangeSelectedWindow extends ExecutorEvent {
  final Arrangement arrangement;
  const RequestArrangeSelectedWindow(this.arrangement);
}

class RequestSelectWindow extends ExecutorEvent {
  final WindowInfo window;
  const RequestSelectWindow(this.window);
}

class RequestRemoveWindow extends ExecutorEvent {
  final WindowInfo window;
  const RequestRemoveWindow(this.window);
}

class RequestCaptureNewWindow extends ExecutorEvent {
  const RequestCaptureNewWindow();
}

class RequestStopCapturing extends ExecutorEvent {
  const RequestStopCapturing();
}

class RequestCaptureAllWindows extends ExecutorEvent {
  const RequestCaptureAllWindows();
}

class RequestCloseAllWindows extends ExecutorEvent {
  const RequestCloseAllWindows();
}
