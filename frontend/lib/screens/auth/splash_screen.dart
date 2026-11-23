import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/user_model.dart';
import '../main_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start the splash animation.
    final animationFuture = _controller.forward();

    // Keep the splash screen visible for at least 900 milliseconds.
    final minimumDelay = Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    AuthStatus authStatus;

    try {
      // Check the user's saved login session.
      authStatus = await ref.read(authProvider.notifier).checkSession();
    } catch (error, stackTrace) {
      debugPrint('Session check failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      authStatus = AuthStatus.unauthenticated;
    }

    // Wait for animation and minimum display duration.
    await Future.wait<void>([
      animationFuture,
      minimumDelay,
    ]);

    if (!mounted) return;

    // Preload data if the user is already authenticated.
    if (authStatus == AuthStatus.authenticated) {
      try {
        await Future.wait([
          ref.read(tripListProvider.notifier).fetchTrips(),
          ref.read(expenseListProvider.notifier).fetchExpenses(),
        ]).timeout(
          const Duration(milliseconds: 1200),
        );
      } catch (error) {
        debugPrint('Data preloading failed: $error');
      }
    }

    if (!mounted) return;

    // Select the appropriate destination.
    Widget destination;

switch (authStatus) {
  case AuthStatus.authenticated:
    destination = const MainScreen();
    break;

  case AuthStatus.firstTime:
    destination = const OnboardingScreen();
    break;

  case AuthStatus.unauthenticated:
  case AuthStatus.initial:
    destination = const LoginScreen();
    break;
}

    // Navigate to the selected screen.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return destination;
        },
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Icon(
            Icons.location_on,
            size: 100,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
