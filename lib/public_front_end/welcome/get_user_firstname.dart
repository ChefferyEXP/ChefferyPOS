// Cheffery - get_user_firstname.dart
//
// This page is designed to get the first name from the user if they have never entered their phone number before.
// It will store their first name and put it on the reciept. Also gets the stores id for checkout process

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_widgets/confirm_dialog_widget.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';

class GetUserFirstNamePage extends ConsumerStatefulWidget {
  const GetUserFirstNamePage({super.key});

  @override
  ConsumerState<GetUserFirstNamePage> createState() =>
      _GetUserFirstNamePageState();
}

class _GetUserFirstNamePageState extends ConsumerState<GetUserFirstNamePage> {
  final _firstNameController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    super.dispose();
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

  Future<void> _finish(String phoneE164) async {
    if (_loading) return;

    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() => _error = 'Please enter your first name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseProvider);

      // Insert and return the created row so we can set the active POS customer.
      final created = await supabase
          .from('pos_users')
          .insert({
            'phone_number': phoneE164,
            'first_name': firstName,
            // created_at + last_seen_at handled by defaults
          })
          .select('id, phone_number, first_name')
          .single();

      final id = created['id'] as int;
      final phone = (created['phone_number'] as String?) ?? phoneE164;
      final name = (created['first_name'] as String?)?.trim();

      // Set active customer providers (session state)
      ref.read(activePosUserIdProvider.notifier).state = id;
      ref.read(activePosUserPhoneProvider.notifier).state = phone;
      ref.read(activePosUserFirstNameProvider.notifier).state = name;

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/menu');
    } catch (e) {
      setState(() => _error = 'Could not create user. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmCancel() async {
    if (_loading) return;

    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ConfirmDialog(
          title: 'Cancel setup?',
          message:
              'Are you sure you would like to cancel?\nYour account creation will be void.',
          onConfirmText: 'Yes',
          onCancelText: 'No',
          primaryColor: AppColors.accent,
        );
      },
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneE164 = ModalRoute.of(context)?.settings.arguments as String?;

    return WillPopScope(
      onWillPop: () async {
        await _confirmCancel();
        return false;
      },
      child: Scaffold(
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

              // ===== Back arrow (with confirm) =====
              Positioned(
                top: 12,
                left: 12,
                child: SafeArea(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _confirmCancel,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
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
                              'What’s your first name?',
                              style: AppTextStyles.title.copyWith(fontSize: 26),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 22),

                          TextField(
                            controller: _firstNameController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (phoneE164 != null) _finish(phoneE164);
                            },
                            decoration: _inputDecoration('First name'),
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
                              onPressed: (_loading || phoneE164 == null)
                                  ? null
                                  : () => _finish(phoneE164),
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
                                  : Text(
                                      'Continue',
                                      style: AppTextStyles.button,
                                    ),
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
      ),
    );
  }
}
