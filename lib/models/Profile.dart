import 'package:isar/isar.dart';

import 'AppInfo.dart';

part 'generated/Profile.g.dart';

@collection
class Profile {
  final Id id;
  final String name;
  final String? description;
  final List<AppInfo> apps;
  final bool launchAtStartup;

  Profile(
      {this.id = Isar.autoIncrement,
      required this.name,
      this.description,
      this.apps = const [],
      this.launchAtStartup = false});

  Profile copyWith(
      {Id? id,
      String? name,
      String? description,
      List<AppInfo>? apps,
      bool? launchAtStartup}) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      apps: apps ?? this.apps,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
    );
  }
}
