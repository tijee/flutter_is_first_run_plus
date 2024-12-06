library is_first_run;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsFirstRun {
  static const _firstRunSettingsKey = 'is_first_run';
  static const _firstCallSettingsKey = 'is_first_call';
  static const _versionSettingsKey = 'version';

  static bool? _isFirstRun;
  static int? _previousBuild;
  static int? _currentBuild;

  static const _dbName = 'isFirstRun';
  static late final Box _db;

  /// Returns true if this is the first time this function has been called
  /// since installing the app, otherwise false.
  ///
  /// In contrast to [IsFirstRun.isFirstRun()], this method only returns true
  /// on the first call after installing the app, while [IsFirstRun.isFirstRun()] continues
  /// to return true as long as the app is running after calling it the first time after installing it.
  static Future<bool> isFirstCall() async {
    await _ensureInitialized();
    bool? firstCall = _db.get(_firstCallSettingsKey);
    if (firstCall == null) {
      // check in shared preferences for compatibility with older versions (<= 1.1.0)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        firstCall = prefs.getBool(_firstCallSettingsKey);
      } on Exception {
        firstCall = true;
      }
    }
    firstCall ??= true;
    await _db.put(_firstCallSettingsKey, false);

    return firstCall;
  }

  /// Returns true if this is the first time this function has been called
  /// since installing the given version (build number) of the app, otherwise false.
  ///
  /// In contrast to [IsFirstRun.isFirstRun()], this method only returns true
  /// on the first call after installing the app, while [IsFirstRun.isFirstRun()] continues
  /// to return true as long as the app is running after calling it the first time after installing it.
  static Future<bool> isFirstCallSince({required int build}) async {
    if (_currentBuild == null) _currentBuild = await _getCurrentBuild();
    // Read the last build saved to the database:
    // If no function has been called since the last update,
    // it will be the previous version.
    // Otherwise it will already be the current version,
    // thus this function will return false.
    await _ensureInitialized();
    int? lastBuild = _db.get(_versionSettingsKey);
    if (lastBuild == null) {
      // check in shared preferences for compatibility with older versions (<= 1.1.0)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        lastBuild = prefs.getInt(_versionSettingsKey);
      } on Exception {
        lastBuild = 0;
      }
    }
    lastBuild ??= 0;
    await _db.put(_versionSettingsKey, _currentBuild!);

    // Return true if the current build is at least the required build,
    // and if the last stored build is less than the required build.
    return _currentBuild! >= build && lastBuild < build;
  }

  /// Returns true if this is the first time you call this method
  /// since installing the app, otherwise false.
  ///
  /// In contrast to [IsFirstRun.isFirstCall()], this method continues
  /// to return true as long as the app keeps running after the first call after installing the app,
  /// while [IsFirstRun.isFirstCall()] returns true only on the first call after installing the app.
  static Future<bool> isFirstRun() async {
    if (_isFirstRun != null) {
      return _isFirstRun!;
    } else {
      await _ensureInitialized();
      bool? isFirstRun = _db.get(_firstRunSettingsKey);
      if (isFirstRun == null) {
        // check in shared preferences for compatibility with older versions (<= 1.1.0)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        try {
          isFirstRun = prefs.getBool(_firstRunSettingsKey);
        } on Exception {
          isFirstRun = true;
        }
      }
      isFirstRun ??= true;
      await _db.put(_firstRunSettingsKey, false);
      if (_isFirstRun == null) _isFirstRun = isFirstRun;
      return isFirstRun;
    }
  }

  /// Returns true if this is the first time you call this method
  /// since installing the given version (build number) of the app, otherwise false.
  ///
  /// In contrast to [IsFirstRun.isFirstCall()], this method continues
  /// to return true as long as the app keeps running after the first call after installing the app,
  /// while [IsFirstRun.isFirstCall()] returns true only on the first call after installing the app.
  static Future<bool> isFirstRunSince({required int build}) async {
    if (_currentBuild == null) _currentBuild = await _getCurrentBuild();
    // If _previousBuild has already been read from the shared preferences,
    // do not read it again because it may have change for isFirstCall
    // to have the most recent value.
    if (_previousBuild == null) {
      await _ensureInitialized();
      _previousBuild = _db.get(_versionSettingsKey);
      if (_previousBuild == null) {
        // check in shared preferences for compatibility with older versions (<= 1.1.0)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        try {
          _previousBuild = prefs.getInt(_versionSettingsKey);
        } on Exception {
          _previousBuild = 0;
        }
      }
      _previousBuild ??= 0;
      // Update the database with the current build,
      // so isFirstCall can detect the change.
      await _db.put(_versionSettingsKey, _currentBuild!);
    }
    // Return true if the current build is at least the required build,
    // and if the previous build was less than the required build.
    return _currentBuild! >= build && _previousBuild! < build;
  }

  /// Resets the plugin.
  ///
  /// The first call to [IsFirstRun.isFirstCall()] after calling [reset()]
  /// method will return true, subsequent calls will return false.
  ///
  /// Calls to [IsFirstRun.isFirstRun()] after calling [reset()] will return true
  /// for as long as the app is running after calling [[IsFirstRun.isFirstRun()]]
  /// the first time after the reset.
  /// After a restart of the app, [IsFirstRun.isFirstRun()] will return false.
  static Future<void> reset() async {
    await Future.wait([
      _db.put(_firstRunSettingsKey, true),
      _db.put(_firstCallSettingsKey, true),
      _db.put(_versionSettingsKey, '0.0.0'),
    ]);
  }

  static Future<int> _getCurrentBuild() async =>
      int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;

  static Future<void> _ensureInitialized() async {
    if (!Hive.isBoxOpen(_dbName)) {
      await Hive.initFlutter();
      _db = await Hive.openBox(_dbName);
    }
  }
}
