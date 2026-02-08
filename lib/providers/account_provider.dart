import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_mode.dart';

class AccountNotifier extends StateNotifier<AccountMode> {
  AccountNotifier() : super(AccountMode.personal);

  void toggle() {
    state = state == AccountMode.personal
        ? AccountMode.business
        : AccountMode.personal;
  }

  void setMode(AccountMode mode) {
    state = mode;
  }
}

final accountModeProvider =
    StateNotifierProvider<AccountNotifier, AccountMode>(
  (ref) => AccountNotifier(),
);
