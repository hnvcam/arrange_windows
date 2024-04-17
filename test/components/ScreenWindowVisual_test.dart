import 'package:arrange_windows/Native.dart';
import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/models/ScreenInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrange_windows/components/ScreenWindowVisual.dart';
import 'package:mockito/mockito.dart';

import '../testUtils.mocks.dart';

void main() {
  final mockNative = MockNative();
  Native.testInstance(mockNative);

  group('one screen', () {
    final screen = ScreenInfo(
      name: 'Test Screen',
      width: 1024,
      height: 768,
      x: 0,
      y: 0,
      visibleX: 0,
      visibleY: 25,
      visibleWidth: 1024,
      visibleHeight: 743,
      safeTop: 0,
      safeLeft: 0,
      safeBottom: 0,
      safeRight: 0,
    );

    setUp(() {
      reset(mockNative);
      when(mockNative.allScreens)
          .thenAnswer((realInvocation) => Future.value([screen]));
    });

    testWidgets('renders screen correctly', (WidgetTester tester) async {
      when(mockNative.getAllWindows(any))
          .thenAnswer((realInvocation) => Future.value([]));

      // default constraint always is 800x600
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider(
          create: (BuildContext context) => ExecutorBloc(),
          child: const ScreenWindowVisual(),
        ),
      ));
      await tester.pump(const Duration(microseconds: 100));

      expect(find.text('Test Screen'), findsOneWidget);
      await expectLater(find.byType(ScreenWindowVisual),
          matchesGoldenFile('singleScreen.png'));
    });
  });
}
