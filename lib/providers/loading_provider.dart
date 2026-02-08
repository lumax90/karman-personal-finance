import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the initial data load is complete
final dataLoadingProvider = StateProvider<bool>((ref) => true);
