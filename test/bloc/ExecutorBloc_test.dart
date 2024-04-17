import 'dart:ffi';
import 'dart:ui';

import 'package:arrange_windows/Native.dart';
import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/bloc/ProfileBloc.dart';
import 'package:arrange_windows/models/AppInfo.dart';
import 'package:arrange_windows/models/Profile.dart';
import 'package:arrange_windows/models/ScreenInfo.dart';
import 'package:arrange_windows/models/WindowInfo.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../testUtils.mocks.dart';

main() {
  final mockNative = MockNative();
  Native.testInstance(mockNative);
  final screen1 = ScreenInfo(
    width: 1920,
    height: 1080,
    x: 0,
    y: 0,
    visibleX: 0,
    visibleY: 25,
    visibleWidth: 1920,
    visibleHeight: 1055,
    safeTop: 0,
    safeLeft: 0,
    safeBottom: 0,
    safeRight: 0,
  );

  final screen2 = ScreenInfo(
    width: 1080,
    height: 1920,
    x: 1920,
    y: -870,
    visibleX: 1920,
    visibleY: 25,
    visibleWidth: 1080,
    visibleHeight: 1895,
    safeTop: 0,
    safeLeft: 0,
    safeBottom: 0,
    safeRight: 0,
  );

  final window = WindowInfo(
    processId: 1,
    windowNumber: 1,
    x: 100,
    y: 50,
    width: 800,
    height: 600,
    sharingState: 1,
    layer: 0,
    alpha: 1,
    bundleIdentifier: 'app',
    bundleURL: '/Application/app',
    onScreen: true,
  );
  late Profile profile;

  setUp(() {
    when(mockNative.allScreens)
        .thenAnswer((_) => Future.value([screen1, screen2]));
    when(mockNative.getAllWindows(any))
        .thenAnswer((realInvocation) => Future.value([window]));
  });

  blocTest('On create, load all screens and windows',
      build: () => ExecutorBloc(),
      expect: () => [
            ExecutorState(screens: [screen1, screen2], windows: [window])
          ],
      verify: (bloc) {
        verify(mockNative.allScreens).called(1);
        verify(mockNative.getAllWindows([screen1, screen2])).called(1);
      });

  blocTest(
      'Load profile windows must launch missing apps and set Frame for all',
      setUp: () {
        final missingApp = AppInfo();
        missingApp.bundleIdentifier = 'missingApp';
        missingApp.path = '/Application/missingApp';
        missingApp.left = 0;
        missingApp.top = 0;
        missingApp.width = 100;
        missingApp.height = 100;
        final existingApp = AppInfo();
        existingApp.bundleIdentifier = 'app';
        existingApp.path = '/Application/app';
        existingApp.left = 0;
        existingApp.top = 0;
        existingApp.width = 100;
        existingApp.height = 100;

        profile = Profile(name: 'test', apps: [missingApp, existingApp]);

        when(mockNative.launchApp(any)).thenAnswer((realInvocation) {
          // after launching, return 2 windows
          when(mockNative.getAllWindows(any))
              .thenAnswer((realInvocation) => Future.value([
                    window,
                    WindowInfo(
                        processId: 2,
                        windowNumber: 2,
                        x: 100,
                        y: 100,
                        width: 200,
                        height: 2,
                        sharingState: 1,
                        layer: 0,
                        alpha: 1.0,
                        bundleIdentifier: missingApp.bundleIdentifier,
                        bundleURL: missingApp.path)
                  ]));
          return Future.value(1);
        });
        when(mockNative.setWindowFrame(any, any))
            .thenAnswer((realInvocation) => Future.value(existingApp.rect));
      },
      build: () => ExecutorBloc(),
      act: (bloc) => bloc.add(RequestLoadProfileWindows(profile)),
      verify: (bloc) {
        final launch = verify(mockNative.launchApp(captureAny)).captured;
        final launchApp = launch[0] as AppInfo;
        expect(launchApp.bundleIdentifier, 'missingApp');
        verify(mockNative.setWindowFrame(
                any, const Rect.fromLTWH(0, 0, 100, 100)))
            .called(2);
      });

  blocTest(
    'Select window',
    build: () => ExecutorBloc(),
    act: (bloc) => bloc.add(RequestSelectWindow(window)),
    verify: (bloc) {
      expect(bloc.state.selectedWindow, window);
    },
  );

  blocTest('Arrange select window must call native',
      setUp: () {
        when(mockNative.setWindowFrame(any, any))
            .thenAnswer((realInvocation) => Future.value(window.rect));
      },
      build: () => ExecutorBloc(),
      act: (bloc) async {
        bloc.add(RequestSelectWindow(window));
        while (bloc.state.selectedWindow == null) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
        bloc.add(
            const RequestArrangeSelectedWindow(Arrangement.almostMaximize));
      },
      verify: (bloc) {
        verify(mockNative.setWindowFrame(window, screen1.visibleRect))
            .called(1);
      });

  blocTest('Remove window must remove from state',
      build: () => ExecutorBloc(),
      act: (bloc) async {
        while (!bloc.state.windows.contains(window)) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
        bloc.add(RequestRemoveWindow(window));
      },
      verify: (bloc) {
        expect(bloc.state.windows.contains(window), false);
      });

  blocTest('Select new window to capture',
      setUp: () {
        when(mockNative.startSelecting())
            .thenAnswer((realInvocation) => Future.value(true));
      },
      build: () => ExecutorBloc(),
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const RequestCaptureNewWindow()),
      verify: (bloc) async {
        expect(bloc.state.isSelecting, true);
        verify(mockNative.startSelecting()).called(1);
      });

  blocTest(
    'refresh all windows',
    build: () => ExecutorBloc(),
    act: (bloc) => bloc.add(const RequestCaptureAllWindows()),
    verify: (bloc) {
      verify(mockNative.getAllWindows(any)).called(2);
    },
  );
}
