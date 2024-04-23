import 'package:arrange_windows/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import '../bloc/ProfileBloc.dart';
import '../models/Profile.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int? _groupValue;
  bool _launchAtLogin = false;

  @override
  void initState() {
    super.initState();
    _groupValue = ProfileBloc.read(context)
        .state
        .profiles
        .firstWhereOrNull((element) => element.launchAtStartup)
        ?.id;
    _checkLaunchAtLogin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CheckboxListTile(
              value: _launchAtLogin,
              onChanged: _setLauchAtLogin,
              title: const Text("Launch Arrange Windows at login"),
            ),
            CheckboxListTile(
              value: _groupValue != null,
              onChanged: _setLaunchProfile,
              title: const Text('Launch profile at startup'),
            ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (BuildContext context, ProfileState state) {
                      return ListView.builder(
                        itemBuilder: (context, index) {
                          final profile = state.profiles[index];
                          final fullscreenCount = profile.apps
                              .where((element) => element.fullScreen == true)
                              .length;

                          return RadioListTile(
                            value: profile.id,
                            groupValue: _groupValue,
                            onChanged: (_) => _changeStartUpProfile(profile),
                            title: Text(profile.name,
                                style: theme.textTheme.labelMedium),
                            subtitle: Row(
                              children: [
                                Text(
                                  'Fullscreen: $fullscreenCount',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const Gap(16),
                                Text(
                                    'Windows: ${profile.apps.length - fullscreenCount}',
                                    style: theme.textTheme.bodySmall)
                              ],
                            ),
                            secondary: IconButton(
                                onPressed: () => _confirmDeleteProfile(profile),
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: theme.colorScheme.error,
                                )),
                          );
                        },
                        itemCount: state.profiles.length,
                      );
                    },
                  )),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _setLauchAtLogin(bool? value) async {
    if (value == null) {
      return;
    }
    if (value) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    setState(() {
      _launchAtLogin = value;
    });
  }

  void _setLaunchProfile(bool? value) {
    if (value == null) {
      return;
    }
    if (value) {
      final firstProfile = ProfileBloc.read(context).state.profiles.firstOrNull;
      if (firstProfile != null) {
        _changeStartUpProfile(firstProfile);
      }
    } else {
      ProfileBloc.read(context).add(const RequestClearStartupProfile());
      setState(() {
        _groupValue = null;
      });
    }
  }

  void _changeStartUpProfile(Profile? value) {
    if (value == null) {
      return;
    }
    ProfileBloc.read(context).add(RequestSetStartupProfile(value));
    setState(() {
      _groupValue = value.id;
    });
  }

  Future<void> _checkLaunchAtLogin() async {
    final isEnabled = await launchAtStartup.isEnabled();
    setState(() {
      _launchAtLogin = isEnabled;
    });
  }

  Future<void> _confirmDeleteProfile(Profile profile) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Delete profile'),
              content: Text(
                  'This action is irreversible. Are you sure you want to delete ${profile.name}?'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ]);
        });
    if (result == true && mounted) {
      ProfileBloc.read(context).add(RequestDeleteProfile(profile));
    }
  }
}
