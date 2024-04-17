import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/bloc/ProfileBloc.dart';
import 'package:arrange_windows/utils.dart';
import 'package:arrange_windows/views/ArrangeWindowsView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'models/Profile.dart';
import 'views/SettingsView.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TrayListener {
  bool _showingSettings = false;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'arrange_windows') {
      setState(() {
        _showingSettings = false;
      });
      await windowManager.setResizable(true);
      await windowManager.setSize(const Size(800, 600));
      await windowManager.show();
    } else if (menuItem.key == 'settings') {
      setState(() {
        _showingSettings = true;
      });
      await windowManager.setSize(const Size(640, 480));
      await windowManager.setResizable(false);

      await windowManager.show();
    } else if (menuItem.key == 'exit') {
      windowManager.destroy();
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const textTheme = TextTheme(
        labelLarge: TextStyle(color: Colors.black, fontSize: 20.0),
        labelMedium: TextStyle(color: Colors.black, fontSize: 16.0),
        labelSmall: TextStyle(color: Colors.black, fontSize: 14.0),
        bodyMedium: TextStyle(color: Colors.black, fontSize: 16.0),
        bodySmall: TextStyle(color: Colors.black, fontSize: 14.0),
        bodyLarge: TextStyle(color: Colors.black, fontSize: 20.0));

    return MaterialApp(
      title: 'Arrange Windows',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                textStyle: MaterialStateProperty.all(
                    const TextStyle(color: Colors.black)))),
        navigationRailTheme: NavigationRailThemeData(
            minWidth: 64.0,
            minExtendedWidth: 200.0,
            selectedLabelTextStyle: textTheme.bodySmall,
            unselectedLabelTextStyle: textTheme.bodySmall),
        listTileTheme:
            const ListTileThemeData(visualDensity: VisualDensity.compact),
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ProfileBloc()),
          BlocProvider(create: (_) => ExecutorBloc())
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfileBloc, ProfileState>(
                listener: (BuildContext context, ProfileState state) {
              _addTrayMenu(context, state.profiles);
            }),
            BlocListener<ProfileBloc, ProfileState>(
                listenWhen: (previous, current) =>
                    previous.profiles.isEmpty && current.profiles.isNotEmpty,
                listener: (BuildContext context, ProfileState state) {
                  final startupProfile = state.profiles
                      .firstWhereOrNull((element) => element.launchAtStartup);
                  if (startupProfile != null) {
                    ExecutorBloc.read(context)
                        .add(RequestLoadProfileWindows(startupProfile));
                  }
                })
          ],
          child: DefaultTextStyle(
              style: textTheme.bodyMedium!,
              child: _showingSettings
                  ? const SettingsView()
                  : const ArrangeWindowsView()),
        ),
      ),
    );
  }

  Future<void> _addTrayMenu(
      BuildContext context, List<Profile> profiles) async {
    Menu menu = Menu(items: [
      MenuItem(key: 'arrange_windows', label: 'Arrange Windows'),
      MenuItem(key: 'settings', label: 'Settings'),
      MenuItem.separator(),
      MenuItem.submenu(
          key: 'load_profile',
          label: 'Load profile...',
          submenu: Menu(items: [
            for (final profile in profiles)
              MenuItem(
                key: profile.name,
                label: profile.name,
                onClick: (menuItem) => ExecutorBloc.read(context)
                    .add(RequestLoadProfileWindows(profile)),
              )
          ])),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Exit')
    ]);

    await trayManager.setContextMenu(menu);
  }
}
