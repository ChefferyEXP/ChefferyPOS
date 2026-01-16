// Cheffery - store_setup.dart
//
// This is the page that will be displayed the first time a new store account logs in. It will prompt them for their store information.
// ALL INFORMATION IS REQUIRED. Mechanically enforced.
// If a store would like to proceed later, they can logout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:v0_0_0_cheffery_pos/store_front_end/profile/store_profile.dart';
import 'package:v0_0_0_cheffery_pos/auth/account_context_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';

// ===========================
// Store Setup Constants
// ===========================

// Add / remove store names here
const List<String> storeNames = [
  'FreshBlendz',
  'FreshBlendz Downtown',
  'FreshBlendz North',
  'FreshBlendz South',
];

// Add / remove provinces here
const List<String> applicableProvinces = ['Ontario'];

// ===========================
// Store Setup Page (Profile Incomplete)
// ===========================
class StoreSetupPage extends ConsumerStatefulWidget {
  const StoreSetupPage({super.key});

  @override
  ConsumerState<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends ConsumerState<StoreSetupPage> {
  // ===========================
  // Input Controllers
  // ===========================
  final _storeNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedStoreName;
  String? _selectedProvince;

  // ===========================
  // UI State
  // ===========================
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _storeNumberController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ===========================
  // E.164 helper (Canada/US)
  // ===========================
  String _toE164CanadaUS(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';

    return '+$digits';
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

  // ===========================
  // Load existing store details if any (shouldnt be, but future proof)
  // ===========================
  Future<void> _loadExisting() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final row = await supabase
        .from('stores')
        .select(
          'store_name, store_number, store_street_address, store_city, store_province, store_phone_number',
        )
        .eq('owner_user_id', user.id)
        .maybeSingle();

    if (!mounted || row == null) return;

    setState(() {
      final storeName = row['store_name'] as String?;
      final province = row['store_province'] as String?;

      _selectedStoreName = storeNames.contains(storeName) ? storeName : null;
      _selectedProvince = applicableProvinces.contains(province)
          ? province
          : null;

      _storeNumberController.text = row['store_number'] ?? '';
      _streetController.text = row['store_street_address'] ?? '';
      _cityController.text = row['store_city'] ?? '';
      _phoneController.text = row['store_phone_number'] ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  // ===========================
  // Save Handler
  // ===========================
  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _saving = false;
        _error = 'Not logged in.';
      });
      return;
    }

    // ===========================
    // Validation
    // ===========================
    if (_selectedStoreName == null) {
      setState(() {
        _saving = false;
        _error = 'Please select a store name.';
      });
      return;
    }

    if (_selectedProvince == null) {
      setState(() {
        _saving = false;
        _error = 'Please select a province.';
      });
      return;
    }

    if (_storeNumberController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      setState(() {
        _saving = false;
        _error = 'All fields are required.';
      });
      return;
    }

    final phoneE164 = _toE164CanadaUS(_phoneController.text.trim());

    if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(phoneE164)) {
      setState(() {
        _saving = false;
        _error = 'Enter a valid phone number.';
      });
      return;
    }

    // ===========================
    // Save
    // ===========================
    await supabase.from('stores').upsert({
      'owner_user_id': user.id,
      'store_name': _selectedStoreName,
      'store_number': _storeNumberController.text.trim(),
      'store_street_address': _streetController.text.trim(),
      'store_city': _cityController.text.trim(),
      'store_province': _selectedProvince,
      'store_phone_number': phoneE164,
    }, onConflict: 'owner_user_id');

    if (!mounted) return;

    setState(() {
      _saving = false;
      _message = 'Store profile saved!';
    });

    ref.invalidate(accountContextProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ===== Gradient background (Mahcing to login) =====
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

            // ===== Background logos (Matching to login) =====
            Positioned(
              top: 40,
              left: 40,
              child: Opacity(
                opacity: 0.30,
                child: Image.asset('assets/logos/cheffery.png', width: 240),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 40,
              child: Opacity(
                opacity: 0.30,
                child: Image.asset(
                  'assets/logos/freshBlendzLogo.png',
                  width: 300,
                ),
              ),
            ),

            // ===== Soft overlay of logos =====
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

            // ===== Main card =====
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
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
                        // ===== Top row: title + profile icon =====
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Complete Store Profile',
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const StoreProfilePage(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white.withOpacity(0.95),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'Enter your store details to finish setup.',
                          style: AppTextStyles.subtitle.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ===== Store Name (Dropdown) =====
                        DropdownButtonFormField<String>(
                          value: _selectedStoreName,
                          items: storeNames
                              .map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStoreName = v),
                          decoration: _inputDecoration('Store Name'),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 14),

                        // ===== Store Number =====
                        TextField(
                          controller: _storeNumberController,
                          decoration: _inputDecoration('Store Number'),
                        ),
                        const SizedBox(height: 14),

                        // ===== Street =====
                        TextField(
                          controller: _streetController,
                          decoration: _inputDecoration('Street Address'),
                        ),
                        const SizedBox(height: 14),

                        // ===== City =====
                        TextField(
                          controller: _cityController,
                          decoration: _inputDecoration('City'),
                        ),
                        const SizedBox(height: 14),

                        // ===== Province (Dropdown) =====
                        DropdownButtonFormField<String>(
                          value: _selectedProvince,
                          items: applicableProvinces
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedProvince = v),
                          decoration: _inputDecoration('Province'),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 14),

                        // ===== Phone =====
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Phone Number'),
                        ),

                        const SizedBox(height: 16),

                        // ===== Error =====
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

                        // ===== Success =====
                        if (_message != null)
                          Container(
                            margin: EdgeInsets.only(
                              top: _error != null ? 12 : 0,
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
                              _message!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 22),

                        // ===== Save Button =====
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save & Continue',
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
    );
  }
}
