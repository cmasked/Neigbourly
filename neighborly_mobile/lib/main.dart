import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_theme.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/auth/views/login_screen.dart';
import 'package:neighborly/features/home/views/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NeighborlyApp()));
}

class NeighborlyApp extends ConsumerWidget {
  const NeighborlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Neighborly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Global backdrop
            Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/backdrop.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
              ),
            ),
            // Semi-transparent surface to soften it globally
            Container(color: AppColors.surface.withOpacity(0.85)),
            // The actual app content on top
            if (child != null) child,
          ],
        );
      },
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState is AuthLoading) {
      return const _SplashScreen();
    }
    if (authState is Authenticated) {
      return const HomeShell();
    }
    // Unauthenticated or AuthError
    return const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          Center(
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
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
        ],
      ),
    );
  }
}
