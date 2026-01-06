// Cheffery - login.dart
/*
This file contains the LoginPage UI
- It allows:
-- Login
-- Sign Up
-- Forgot Password

This page uses RiverPod + AuthController to perform Supabase actions
- Listens for user changes to automatically route to the menu page
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/designs.dart';
import '../../auth/auth_controller.dart';
import '../../auth/auth_provider.dart';

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
  final _confirmPasswordController = TextEditingController();

  // UI Switch Flags
  bool _isSignUp = false;
  bool _forgotPassword = false;

  // Riverpod Subscription
  // stores a handle to a Riverpod listener so the widget can react to provider changes (like login success) and safely stop listening when the widget is disposed.
  ProviderSubscription? _userSub;

  @override
  void initState() {
    super.initState();
    // ---- Listener for authentication changes (CurrentUserProvider)----
    // ListenManual is used to listen outside of build() and cleanly unsuscribe in dispose
    //
    // When currentUserProvider becomes non-null, login will succeed (or on session restore)
    _userSub = ref.listenManual(currentUserProvider, (previous, next) {
      // next is the current value of the currentUserProvider
      // If its not null, there is a logged in user
      if (next != null) {
        // Replace login page with locations page
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  // dipose() is used to clean up resources
  void dispose() {
    // Stop listening to the provider (avoiding memory leaks)
    _userSub?.close();
    // Dispose controllers to free resources (avoid memory leaks)
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to handle submit action for all three modes
  Future<void> _submit() async {
    // Read current inputs
    final email = _emailController.text;
    final password = _passwordController.text;

    // Clear old UI messages before starting new action
    ref.read(authControllerProvider.notifier).clearMessages();

    // ===== Mode: Forgot Password =====
    if (_forgotPassword) {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(email: email);
      return;
    }

    // ===== Mode: Sign Up =====
    if (_isSignUp) {
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (password != confirmPassword) {
        ref
            .read(authControllerProvider.notifier)
            .setError('Passwords do not match');
        return;
      }

      await ref
          .read(authControllerProvider.notifier)
          .signUp(email: email, password: password);

      final ui = ref.read(authControllerProvider);
      if (ui.error == null) {
        setState(() {
          _isSignUp = false;
          _forgotPassword = false;
        });

        _passwordController.clear();
        _confirmPasswordController.clear();
      }

      return;
    }

    // ===== Mode: Login (Default) =====
    await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);
  }

  // Function to toggle between Login/Signup UI
  // Also resets forgot password mode and clears old messages
  void _toggleForm() {
    setState(() {
      _isSignUp = !_isSignUp;
      _forgotPassword = false;
    });

    _passwordController.clear();
    _confirmPasswordController.clear();

    ref.read(authControllerProvider.notifier).clearMessages();
  }

  //Toggles forgot password UI
  void _toggleForgotPassword() {
    setState(() {
      _forgotPassword = !_forgotPassword;
    });
    //Clear old messages
    ref.read(authControllerProvider.notifier).clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    // Watch UI state from AuthController to revuild when loading/error/message changes
    final ui = ref.watch(authControllerProvider);

    // Compute UI labels based on the current mode
    final title = _forgotPassword
        ? 'Reset Password'
        : _isSignUp
        ? 'Sign Up'
        : 'Login';

    final submitLabel = _forgotPassword
        ? 'Send Reset Email'
        : _isSignUp
        ? 'Sign Up'
        : 'Login';

    // If user is in forgot password mode, hide the password field
    final showPassword = !_forgotPassword;

    // ===========================
    // Build the screen
    // ===========================
    return Scaffold(
      //Background of entire page
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: AppTextStyles.title),
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

              // =============== Password field ===============
              if (showPassword) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                // =============== Confirm Password (Sign Up only) ===============
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Confirm Password',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // =============== Error Message ===============
              if (ui.error != null)
                Text(
                  ui.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              // =============== Success/Info message===============
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
                      : Text(submitLabel, style: AppTextStyles.button),
                ),
              ),

              const SizedBox(height: 16),

              // =============== Forgot password ===============
              if (!_forgotPassword)
                TextButton(
                  onPressed: ui.loading ? null : _toggleForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              // =============== Toggle between modes ===============
              // - Back to login (if in forgot pass mode)
              // - Switch to Login or signup otherwise
              TextButton(
                onPressed: ui.loading
                    ? null
                    : (_forgotPassword ? _toggleForgotPassword : _toggleForm),
                child: Text(
                  _forgotPassword
                      ? 'Back to Login'
                      : _isSignUp
                      ? 'Already have an account? Login'
                      : 'Don\'t have an account? Sign Up',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
