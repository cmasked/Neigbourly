import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/auth/views/login_screen.dart';
import 'package:neighborly/features/auth/views/register_screen.dart';
import 'package:neighborly/features/home/views/home_shell.dart';
import 'package:neighborly/features/items/views/browse_screen.dart';
import 'package:neighborly/features/items/views/item_detail_screen.dart';
import 'package:neighborly/features/items/views/new_item_screen.dart';
import 'package:neighborly/features/requests/views/requests_screen.dart';
import 'package:neighborly/features/transactions/views/transactions_screen.dart';
import 'package:neighborly/features/profile/views/profile_screen.dart';

// Simple custom router since go_router requires a dependency.
// We use a Navigator-based approach managed by Riverpod.

/// Route names.
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String browse = '/browse';
  static const String itemDetail = '/item-detail';
  static const String newItem = '/new-item';
  static const String requests = '/requests';
  static const String transactions = '/transactions';
  static const String profile = '/profile';
}

/// Provides a MaterialApp.router config using a simple Navigator approach.
/// The app listens to auth state and redirects accordingly.
final appRouterProvider = Provider<RouterConfig<Object>>((ref) {
  return _AppRouterConfig(ref);
});

class _AppRouterConfig implements RouterConfig<Object> {
  final Ref _ref;

  _AppRouterConfig(this._ref);

  @override
  RouteInformationParser<Object>? get routeInformationParser => null;

  @override
  RouteInformationProvider? get routeInformationProvider => null;

  @override
  RouterDelegate<Object> get routerDelegate => _AppRouterDelegate(_ref);

  @override
  BackButtonDispatcher? get backButtonDispatcher => null;
}

class _AppRouterDelegate extends RouterDelegate<Object> with ChangeNotifier {
  final Ref _ref;

  _AppRouterDelegate(this._ref);

  @override
  Widget build(BuildContext context) {
    // We use a simple Consumer to decide which top-level widget to show.
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authProvider);

        if (authState is AuthLoading) {
          return const _SplashScreen();
        }

        if (authState is Unauthenticated || authState is AuthError) {
          return Navigator(
            key: const ValueKey('auth'),
            onPopPage: (route, result) => route.didPop(result),
            pages: const [
              MaterialPage(child: LoginScreen()),
            ],
          );
        }

        // Authenticated
        return const HomeShell();
      },
    );
  }

  @override
  Future<bool> popRoute() async => false;

  @override
  Future<void> setNewRoutePath(configuration) async {}
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5A46D6), Color(0xFF4E37CA)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.home_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Neighborly',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
