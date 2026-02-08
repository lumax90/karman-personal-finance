import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/deal_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/loading_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/activity_provider.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'services/revenuecat_service.dart';
import 'providers/revenuecat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  await RevenueCatService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: FinanceCrmApp()));
}

class FinanceCrmApp extends ConsumerStatefulWidget {
  const FinanceCrmApp({super.key});

  @override
  ConsumerState<FinanceCrmApp> createState() => _FinanceCrmAppState();
}

class _FinanceCrmAppState extends ConsumerState<FinanceCrmApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuth();
      // Listen for auth state changes and load/clear data accordingly
      ref.listenManual<AuthState>(authProvider, (prev, next) {
        if (prev?.status == next.status) return;
        if (next.status == AuthStatus.authenticated) {
          _loadAllData();
          // Sync RevenueCat with auth user
          if (next.user != null) {
            RevenueCatService.login(next.user!.id).then((_) {
              syncSubscriptionStatus(ref);
            });
          }
        } else if (next.status == AuthStatus.unauthenticated) {
          _clearAllData();
          RevenueCatService.logout();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Karman',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _buildHome(authState),
    );
  }

  void _loadAllData() {
    Future.microtask(() async {
      ref.read(dataLoadingProvider.notifier).state = true;
      await Future.wait([
        ref.read(transactionListProvider.notifier).fetchAll(),
        ref.read(subscriptionListProvider.notifier).fetchAll(),
        ref.read(goalListProvider.notifier).fetchAll(),
        ref.read(reminderListProvider.notifier).fetchAll(),
        ref.read(contactListProvider.notifier).fetchAll(),
        ref.read(dealListProvider.notifier).fetchAll(),
        ref.read(invoiceListProvider.notifier).fetchAll(),
        ref.read(activityListProvider.notifier).fetchAll(),
      ]);
      ref.read(dataLoadingProvider.notifier).state = false;
    });
  }

  void _clearAllData() {
    ref.read(transactionListProvider.notifier).clear();
    ref.read(subscriptionListProvider.notifier).clear();
    ref.read(goalListProvider.notifier).clear();
    ref.read(reminderListProvider.notifier).clear();
    ref.read(contactListProvider.notifier).clear();
    ref.read(dealListProvider.notifier).clear();
    ref.read(invoiceListProvider.notifier).clear();
    ref.read(activityListProvider.notifier).clear();
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const AuthScreen();
    }
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnim,
              child: const Text(
                'Karman',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnim,
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
