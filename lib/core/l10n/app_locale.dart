import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { tr, en }

class AppLocaleNotifier extends StateNotifier<AppLanguage> {
  AppLocaleNotifier() : super(AppLanguage.tr);

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLocaleNotifier, AppLanguage>(
  (ref) => AppLocaleNotifier(),
);
