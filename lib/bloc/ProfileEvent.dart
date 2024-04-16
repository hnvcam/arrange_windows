part of 'ProfileBloc.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

class _RepositoryUpdateProfiles extends ProfileEvent {
  final List<Profile> profiles;
  const _RepositoryUpdateProfiles(this.profiles);
}

class RequestLoadProfiles extends ProfileEvent {
  const RequestLoadProfiles();
}

class RequestSaveProfile extends ProfileEvent {
  final Profile profile;
  const RequestSaveProfile(this.profile);
}

class RequestClearStartupProfile extends ProfileEvent {
  const RequestClearStartupProfile();
}

class RequestSetStartupProfile extends ProfileEvent {
  final Profile profile;
  const RequestSetStartupProfile(this.profile);
}
