// Cheffery - login.dart
/*
This file contains the LoginPage UI
- It allows:
-- Login

This page uses RiverPod + AuthController to perform Supabase actions
- Listens for user changes to automatically route to the menu page
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

// State object for LoginPage - ConsumerState gives 'ref' for read/watch riverpod providers.
class _LoginPageState extends ConsumerState<LoginPage> {
  // Input Fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  // dispose() to clean up resources
  void dispose() {
    // Dispose controllers to free resources
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // Submit Handler
  Future<void> _submit() async {
    // Read current inputs
    final email = _emailController.text;
    final password = _passwordController.text;

    // Clear old UI messages before starting new action
    ref.read(authControllerProvider.notifier).clearMessages();

    await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    // Watch UI state from AuthController to rebuild when loading/error/message changes
    final ui = ref.watch(authControllerProvider);

    // ===========================
    // Build the screen
    // ===========================
    return Scaffold(
      // Background of entire page
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // =============== Title ===============
              Text('Cheffery POS Store Login', style: AppTextStyles.title),
              const SizedBox(height: 32),

              // =============== Email Field ===============
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // =============== Password Field ===============
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // =============== Error Message ===============
              if (ui.error != null)
                Text(
                  ui.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              // =============== Success / Info Message ===============
              if (ui.message != null)
                Text(
                  ui.message!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              // =============== Submit Button ===============
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ui.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.button,
                    ),
                    padding: AppPadding.button,
                  ),
                  child: ui.loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Login', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
