import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/features/auth/providers/auth_provider.dart';
import 'package:neighborly/features/auth/views/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Default community for quick testing
  String _selectedCommunity = 'c1000000-0000-0000-0000-000000000001';

  final _communities = {
    'c1000000-0000-0000-0000-000000000001': 'Maple Heights',
    'c1000000-0000-0000-0000-000000000002': 'Sunrise Tech',
    'c1000000-0000-0000-0000-000000000003': 'Green Valley',
  };

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
          _selectedCommunity,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final errorMsg = authState is AuthError ? authState.message : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Content ──────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // ─── Logo & Brand ───────────────────────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.home_rounded,
                          size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    Text('Welcome\nback.',
                        style: AppTypography.displaySmall
                            .copyWith(height: 1.15)),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your neighborhood community',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: 40),

                    // ─── Error Banner ───────────────────────────
                    if (errorMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(errorMsg,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ─── Form ───────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Community Selector
                          DropdownButtonFormField<String>(
                            value: _selectedCommunity,
                            decoration: const InputDecoration(
                              labelText: 'Neighborhood Community',
                              prefixIcon: Icon(Icons.location_city_rounded),
                            ),
                            items: _communities.entries
                                .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCommunity = v!),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          GradientPillButton(
                            label: 'Sign In',
                            onPressed: isLoading ? null : _handleLogin,
                            isLoading: isLoading,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── Register Link ──────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodyMedium,
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: AppTypography.labelLarge
                                    .copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
