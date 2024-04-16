part of 'ProfileBloc.dart';

class ProfileState extends Equatable {
  static const empty = ProfileState([]);

  final List<Profile> profiles;

  const ProfileState(this.profiles);

  @override
  List<Object?> get props => [profiles];
}
