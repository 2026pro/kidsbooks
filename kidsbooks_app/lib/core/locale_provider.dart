import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLanguageCodes = ['mn', 'en', 'fr', 'es', 'ko', 'zh', 'ru'];

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('mn')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    if (code != null && supportedLanguageCodes.contains(code)) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
