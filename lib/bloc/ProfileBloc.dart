import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../IsarDB.dart';
import '../models/Profile.dart';

part 'ProfileEvent.dart';
part 'ProfileState.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  static ProfileBloc read(BuildContext buildContext) =>
      buildContext.read<ProfileBloc>();

  ProfileBloc() : super(ProfileState.empty) {
    on<_RepositoryUpdateProfiles>(_onRepositoryUpdateProfiles);
    on<RequestLoadProfiles>(_onLoadProfiles);
    on<RequestSaveProfile>(_onSaveProfile);
    on<RequestClearStartupProfile>(_clearStartupProfile);
    on<RequestSetStartupProfile>(_setStartupProfile);
    on<RequestDeleteProfile>(_deleteProfile);

    add(const RequestLoadProfiles());
  }

  FutureOr<void> _onRepositoryUpdateProfiles(
      _RepositoryUpdateProfiles event, Emitter<ProfileState> emit) {
    emit(ProfileState(event.profiles));
  }

  FutureOr<void> _onLoadProfiles(
      RequestLoadProfiles event, Emitter<ProfileState> emit) async {
    final isar = await IsarDB.instance;
    final profiles = await isar.profiles.where().findAll();
    emit(ProfileState(profiles));
  }

  FutureOr<void> _onSaveProfile(
      RequestSaveProfile event, Emitter<ProfileState> emit) async {
    final isar = await IsarDB.instance;
    await isar.writeTxn(() async {
      await isar.profiles.put(event.profile);
    });
    add(const RequestLoadProfiles());
  }

  FutureOr<void> _clearStartupProfile(
      RequestClearStartupProfile event, Emitter<ProfileState> emit) async {
    final isar = await IsarDB.instance;
    final startupProfiles =
        await isar.profiles.filter().launchAtStartupEqualTo(true).findAll();
    await isar.writeTxn(() async {
      await isar.profiles.putAll(startupProfiles
          .map((e) => e.copyWith(launchAtStartup: false))
          .toList());
    });
    add(const RequestLoadProfiles());
  }

  FutureOr<void> _setStartupProfile(
      RequestSetStartupProfile event, Emitter<ProfileState> emit) async {
    final isar = await IsarDB.instance;
    final startupProfiles =
        await isar.profiles.filter().launchAtStartupEqualTo(true).findAll();
    await isar.writeTxn(() async {
      await isar.profiles.putAll(startupProfiles
          .map((e) => e.copyWith(launchAtStartup: false))
          .toList());
      await isar.profiles.put(event.profile.copyWith(launchAtStartup: true));
    });
    add(const RequestLoadProfiles());
  }

  FutureOr<void> _deleteProfile(
      RequestDeleteProfile event, Emitter<ProfileState> emit) async {
    final isar = await IsarDB.instance;
    await isar.writeTxn(() async {
      await isar.profiles.delete(event.profile.id);
    });
    emit(ProfileState(List.of(state.profiles)
      ..removeWhere((element) => element.id == event.profile.id)));
  }
}
