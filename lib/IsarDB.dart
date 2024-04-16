import 'dart:io';

import 'package:arrange_windows/models/Profile.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarDB {
  const IsarDB._();

  static Isar? _sharedInstance;

  static Future<Isar> get instance async {
    if (_sharedInstance == null || !_sharedInstance!.isOpen) {
      final appDir = await getApplicationDocumentsDirectory();
      _sharedInstance =
          await Isar.open([ProfileSchema], directory: appDir.path);
    }
    return _sharedInstance!;
  }

  @visibleForTesting
  static void testInstance(Isar testInstance) {
    assert(Platform.environment.containsKey('FLUTTER_TEST'),
        'We must not use testInstance other than for testing!!!');
    _sharedInstance = testInstance;
  }

  static Future<void> close() async {
    if (_sharedInstance == null || !_sharedInstance!.isOpen) {
      return;
    }
    await _sharedInstance!.close();
  }
}
