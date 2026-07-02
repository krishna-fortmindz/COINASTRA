import 'package:ai_trading_copilot/services/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  static late final SharedPreferences _prefsInstance;
  static Future<SharedPreferences> init() async {
    return _prefsInstance = await SharedPreferences.getInstance();
  }

//------------------------set value
  static Future<void> setValue(PrefKeys key, dynamic value) async {
    switch (value.runtimeType) {
      case const (String):
        await _prefsInstance.setString(key.name, value as String);
        break;
      case const (int):
        await _prefsInstance.setInt(key.name, value as int);
        break;
      case const (bool):
        await _prefsInstance.setBool(key.name, value as bool);
        break;
      case const (double):
        await _prefsInstance.setDouble(key.name, value as double);
        break;
      default:
        throw Exception("Unsupported type: ${value.runtimeType}");
    }
  }

  ///-----------------------Get value by expected type
  static T? getValue<T>(PrefKeys key, {T? defaultValue}) {
    final Object? value = _prefsInstance.get(key.name);
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// ---------------------Clear all prefs
  static Future<void> clear() async {
    await _prefsInstance.clear();
  }
}
