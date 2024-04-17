import 'dart:io';

import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/bloc/ProfileBloc.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'App.dart';
import 'utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugLog(['Native', '_ArrangeWindowsViewState', 'ExecutorBloc']);
  debugBloc([ExecutorBloc, ProfileBloc]);

  await windowManager.ensureInitialized();

  await trayManager.setIcon('assets/icon/icon.png');

  windowManager.waitUntilReadyToShow(
      const WindowOptions(
          skipTaskbar: true,
          size: Size(800, 600),
          title: 'Arrange Windows'), () async {
    await windowManager.hide();
  });

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
      appName: packageInfo.appName, appPath: Platform.resolvedExecutable);

  runApp(const App());
}
