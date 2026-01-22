// Cheffery - get_user_phonenumber.dart
//
// This page is the first screen after the user taps the welcome screen.
// It prompts the user to to enter their phone number. If it is their first time they will then be taken to the get first name.
// If they are returning it will bring them directly to the menu.
// Phone numbers are normalized before put into database
// Furthermore, if the store puts in their own phone number, it will remove them from POS mode, and bring them back to login

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_store_provider.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_router.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';

class GetUserPhoneNumberPage extends ConsumerStatefulWidget {
  const GetUserPhoneNumberPage({super.key});

  @override
  ConsumerState<GetUserPhoneNumberPage> createState() =>
      _GetUserPhoneNumberPageState();
}

class _GetUserPhoneNumberPageState
    extends ConsumerState<GetUserPhoneNumberPage> {
  final _phoneController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _toE164CanadaUS(String input) {
    final trimmed = input.trim();

    if (trimmed.startsWith('+')) {
      final digits = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
      return digits;
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 10) return '+1$digitsOnly';
    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return '+$digitsOnly';
    }

    return '+$digitsOnly';
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

  Future<void> _continue() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseProvider);

      final e164 = _toE164CanadaUS(_phoneController.text);

      // quick local validation to match your DB constraint
      final valid = RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(e164);
      if (!valid) {
        setState(() {
          _loading = false;
          _error = 'Enter a valid phone number (example: (xxx)-xxx-xxxx).';
        });
        return;
      }

      // Store-phone logout guard (WAIT for provider to resolve)
      final storePhoneRaw = await ref.read(storePhoneProvider.future);
      final storePhoneE164 =
          (storePhoneRaw == null || storePhoneRaw.trim().isEmpty)
          ? ''
          : _toE164CanadaUS(storePhoneRaw.trim());

      if (storePhoneE164.isNotEmpty && storePhoneE164 == e164) {
        if (!mounted) return;

        // same behavior as StoreProfilePage logout
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthRouter()),
          (route) => false,
        );

        // Clear active POS customer just in case
        ref.read(activePosUserIdProvider.notifier).state = null;
        ref.read(activePosUserPhoneProvider.notifier).state = null;
        ref.read(activePosUserFirstNameProvider.notifier).state = null;

        await supabase.auth.signOut();
        return;
      }

      // Look for existing POS user
      final resp = await supabase
          .from('pos_users')
          .select('id, first_name')
          .eq('phone_number', e164)
          .maybeSingle();

      // If found -> set active customer + go to menu
      if (resp != null) {
        final id = resp['id'] as int;

        ref.read(activePosUserIdProvider.notifier).state = id;
        ref.read(activePosUserPhoneProvider.notifier).state = e164;
        ref.read(activePosUserFirstNameProvider.notifier).state =
            (resp['first_name'] as String?)?.trim();

        // Optional: update last_seen_at
        await supabase
            .from('pos_users')
            .update({'last_seen_at': DateTime.now().toIso8601String()})
            .eq('id', id);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/menu');
        return;
      }

      // If not found -> go to first name screen
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/get_user_firstname',
        arguments: e164,
      );
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ===== Gradient background (match Welcome/Login) =====
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

            // ===== Soft overlay =====
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

            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            // ===== Card =====
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
                        Center(
                          child: Text(
                            'Enter your phone number',
                            style: AppTextStyles.title.copyWith(fontSize: 26),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 22),

                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _continue(),
                          decoration: _inputDecoration(
                            'Phone (e.g. (xxx)-xxx-xxxx)',
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (_error != null)
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
                              _error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 22),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Continue', style: AppTextStyles.button),
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
