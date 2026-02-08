import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_locale.dart';
import 'strings.dart';

final stringsProvider = Provider<S>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return S(lang);
});
