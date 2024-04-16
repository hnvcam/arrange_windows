import 'package:arrange_windows/bloc/ExecutorBloc.dart';
import 'package:arrange_windows/models/Profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../bloc/ProfileBloc.dart';
import '../models/AppInfo.dart';

class ProfileActions extends StatefulWidget {
  const ProfileActions({
    super.key,
  });

  @override
  State<ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends State<ProfileActions> {
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();
  final GlobalKey _loadKey = GlobalKey();
  final TextEditingController _textEditingController = TextEditingController();
  bool _dirty = true;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _newProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<ExecutorBloc, ExecutorState>(
      listenWhen: (previous, current) => previous.windows != current.windows,
      listener: (BuildContext context, ExecutorState state) {
        setState(() {
          _dirty = true;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: _fieldKey,
            controller: _textEditingController,
            decoration: InputDecoration(
                labelText: "Profile name",
                labelStyle: theme.textTheme.bodySmall),
            style: theme.textTheme.labelSmall,
            onChanged: _updateProfileName,
            validator: (String? value) =>
                value?.isNotEmpty == true ? null : "Field is required",
          ),
          const Gap(8.0),
          TextButton.icon(
              onPressed: _newProfile,
              icon: const Icon(Icons.add),
              label: const Text("New profile")),
          TextButton.icon(
            onPressed: _dirty ? _saveProfile : null,
            icon: const Icon(Icons.save),
            label: const Text("Save profile"),
          ),
          TextButton.icon(
              key: _loadKey,
              onPressed: _loadProfile,
              icon: const Icon(Icons.restore),
              label: const Text("Load profile"))
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_fieldKey.currentState!.validate()) {
      return;
    }
    final profileBloc = ProfileBloc.read(context);
    final saving = (_profile ??
            profileBloc.state.profiles.firstWhere(
                (element) => element.name == _textEditingController.text,
                orElse: () => Profile(name: _textEditingController.text)))
        .copyWith(
            apps: ExecutorBloc.read(context)
                .state
                .windows
                .map(AppInfo.from)
                .toList());
    profileBloc.add(RequestSaveProfile(saving));
    setState(() {
      _dirty = false;
    });
  }

  Future<void> _loadProfile() async {
    final renderBox = _loadKey.currentContext?.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final select = await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(offset.dx, offset.dy, 0, 0),
        items: [
          for (var profile in ProfileBloc.read(context).state.profiles)
            PopupMenuItem(
              value: profile,
              child: Text(profile.name),
            )
        ]);
    if (select != null && mounted) {
      _profile = select;
      _textEditingController.text = select.name;
      ExecutorBloc.read(context).add(RequestLoadProfileWindows(select));
    }
  }

  void _newProfile() {
    if (_profile != null) {
      setState(() {
        _dirty = true;
      });
    }
    _profile = null;
    _textEditingController.text = 'Untitled';
  }

  void _updateProfileName(String value) {
    _profile = _profile?.copyWith(name: value);
    setState(() {
      _dirty = true;
    });
  }
}
