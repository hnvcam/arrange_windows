import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/models/ScreenInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrange_windows/components/ScreenWindowVisual.dart';

void main() {
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

    testWidgets('renders screen correctly', (WidgetTester tester) async {
      // default constraint always is 800x600
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider(
          create: (BuildContext context) => ExecutorBloc(
              initial: ExecutorState(screens: [screen], windows: const [])),
          child: const ScreenWindowVisual(),
        ),
      ));
      expect(find.text('Test Screen'), findsOneWidget);
      final screenPosition =
          find.byType(Positioned).evaluate().where((element) {
        final rect = (element.renderObject as RenderBox).paintBounds;
        return rect.top == 0.0 &&
            rect.left == 0.0 &&
            rect.width.round() == 799 &&
            rect.height.round() == 600;
      }).firstOrNull;
      expect(screenPosition, isNotNull);
    });
  });
}
