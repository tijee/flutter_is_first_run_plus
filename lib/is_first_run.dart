library is_first_run;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsFirstRun {
  static const _firstRunSettingsKey = 'is_first_run';
  static const _firstCallSettingsKey = 'is_first_call';
  static const _versionSettingsKey = 'version';

  static bool? _isFirstRun;
  static int? _previousBuild;
  static int? _currentBuild;

  /// Returns true if this is the first time this function has been called
  /// since installing the app, otherwise false.
  ///
  /// In contrast to [IsFirstRun.isFirstRun()], this method only returns true
  /// on the first call after installing the app, while [IsFirstRun.isFirstRun()] continues
  /// to return true as long as the app is running after calling it the first time after installing it.
  static Future<bool> isFirstCall() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool firstCall;
    try {
      firstCall = prefs.getBool(_firstCallSettingsKey) ?? true;
    } on Exception {
      firstCall = true;
    }
    await prefs.setBool(_firstCallSettingsKey, false);

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
    // Read the last build saved to the shared preferences:
    // If no function has been called since the last update,
    // it will be the previous version.
    // Otherwise it will already be the current version,
    // thus this function will return false.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastBuild;
    try {
      lastBuild = prefs.getInt(_versionSettingsKey) ?? 0;
    } on Exception {
      lastBuild = 0;
    }
    await prefs.setInt(_versionSettingsKey, _currentBuild!);

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstRun;
      try {
        isFirstRun = prefs.getBool(_firstRunSettingsKey) ?? true;
      } on Exception {
        isFirstRun = true;
      }
      await prefs.setBool(_firstRunSettingsKey, false);
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        _previousBuild = prefs.getInt(_versionSettingsKey) ?? 0;
      } on Exception {
        _previousBuild = 0;
      }
      // Update the shared preferences with the current build,
      // so isFirstCall can detect the change.
      await prefs.setInt(_versionSettingsKey, _currentBuild!);
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_firstRunSettingsKey, true);
    prefs.setBool(_firstCallSettingsKey, true);
    prefs.setString(_versionSettingsKey, '0.0.0');
  }

  static Future<int> _getCurrentBuild() async =>
      int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
}
