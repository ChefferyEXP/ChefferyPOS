// Cheffery - login.dart
/*
This file contains the Login UI
- It only allows for login, because at this point all accounts will be managed by cheffery. Including any signups and password resets required.

This page uses RiverPod + AuthController to perform Supabase actions
- The auth controller listens for user changes to automatically route to the store menu page or admin page
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

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    ref.read(authControllerProvider.notifier).clearMessages();

    await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.accent, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ===== Gradient background =====
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.welcomeTopGradient,
                    AppColors.welcomeBottomGradient,
                  ],
                ),
              ),
            ),

            // ===== Background logos =====
            Positioned(
              top: 40,
              left: 40,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset('assets/logos/cheffery.png', width: 260),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 40,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/logos/freshBlendzLogo.png',
                  width: 320,
                ),
              ),
            ),

            // ===== logo soft overlay for visual appeal =====
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.black.withOpacity(0.06),
                  ],
                ),
              ),
            ),

            // ===== Login Card =====
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // =============== Title ===============
                        Center(
                          child: Text(
                            'Cheffery POS Store Login',
                            style: AppTextStyles.title.copyWith(
                              fontSize:
                                  36, // adjust down as needed (e.g. 24–28)
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // =============== Email Field ===============
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration('Email'),
                        ),

                        const SizedBox(height: 14),

                        // =============== Password Field ===============
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => ui.loading ? null : _submit(),
                          decoration: _inputDecoration('Password'),
                        ),

                        const SizedBox(height: 16),

                        // =============== Error Message ===============
                        if (ui.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.22),
                              ),
                            ),
                            child: Text(
                              ui.error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // =============== Success / Info Message ===============
                        if (ui.message != null)
                          Container(
                            margin: EdgeInsets.only(
                              top: ui.error != null ? 12 : 0,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.22),
                              ),
                            ),
                            child: Text(
                              ui.message!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 22),

                        // =============== Submit Button ===============
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: ui.loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
