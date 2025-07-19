import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

   late SharedPreferences prefs;

  // Inicializar las preferencias
  Future<void> initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  void saveStringPreference(String key, String value) {
    prefs.setString(key, value);
  }

  String? getStringPreference(String key) {
    return prefs.getString(key);
  }

  void saveIntPreference(String key, int value)  {
     prefs.setInt(key, value);
  }

  int? getIntPreference(String key)  {
    return prefs.getInt(key);
  }

  void saveBoolPreference(String key, bool value)  {
     prefs.setBool(key, value);
  }

  bool? getBoolPreference(String key)  {
    return prefs.getBool(key);
  }

  void saveDoublePreference(String key, double value)  {
     prefs.setDouble(key, value);
  }

  double? getDoublePreference(String key)  {
    return prefs.getDouble(key);
  }

  void saveStringListPreference(String key, List<String> value)  {
     prefs.setStringList(key, value);
  }

  List<String>? getStringListPreference(String key)  {
    return prefs.getStringList(key);
  }

  void removeAllSharedPreferences() async {
    prefs.clear();
  }

  void removePreference(String key) async {
    prefs.remove(key);
  }