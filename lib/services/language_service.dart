import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Locale currentLocale = const Locale('lt');

Future<void> loadSavedLanguage() async {
  final prefs = await SharedPreferences.getInstance();

  final lang = prefs.getString('language');

  if (lang != null) {
    currentLocale = Locale(lang);
  }
}
