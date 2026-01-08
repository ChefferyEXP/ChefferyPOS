import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/profile/profile.dart';
import 'package:v0_0_0_cheffery_pos/auth/account_context_provider.dart';

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
  // Input Fields
  // ===========================
  final _storeNameController = TextEditingController();
  final _storeNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _phoneController = TextEditingController();

  // ===========================
  // UI State
  // ===========================
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeNumberController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ===========================
  // Load existing store details (if any)
  // ===========================
  Future<void> _loadExisting() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final row = await supabase
          .from('stores')
          .select(
            'store_name, store_number, store_street_address, store_city, store_province, store_phone_number',
          )
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (!mounted || row == null) return;

      _storeNameController.text = (row['store_name'] as String?) ?? '';
      _storeNumberController.text = (row['store_number'] as String?) ?? '';
      _streetController.text = (row['store_street_address'] as String?) ?? '';
      _cityController.text = (row['store_city'] as String?) ?? '';
      _provinceController.text = (row['store_province'] as String?) ?? '';
      _phoneController.text = (row['store_phone_number'] as String?) ?? '';
    } catch (_) {
      // Silent failure
    }
  }

  @override
  void initState() {
    super.initState();
    // Prefill any existing values (admin might have partially filled)
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
        _error = 'Not logged in. Please log in again.';
      });
      return;
    }

    // Basic validation
    final storeName = _storeNameController.text.trim();
    final storeNumber = _storeNumberController.text.trim();

    if (storeName.isEmpty) {
      setState(() {
        _saving = false;
        _error = 'Please enter a store name.';
      });
      return;
    }

    if (storeNumber.isEmpty) {
      setState(() {
        _saving = false;
        _error = 'Please enter a store number.';
      });
      return;
    }

    try {
      // Update the store row linked to this auth user
      await supabase
          .from('stores')
          .update({
            'store_name': storeName,
            'store_number': storeNumber,
            'store_street_address': _streetController.text.trim().isEmpty
                ? null
                : _streetController.text.trim(),
            'store_city': _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            'store_province': _provinceController.text.trim().isEmpty
                ? null
                : _provinceController.text.trim(),
            'store_phone_number': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'profile_completed': true,
          })
          .eq('owner_user_id', user.id);

      if (!mounted) return;

      setState(() {
        _saving = false;
        _message = 'Store profile saved!';
      });

      // AuthRouter will pick up profile_completed=true on next refresh.
      ref.invalidate(accountContextProvider);
    } on PostgrestException catch (e) {
      setState(() {
        _saving = false;
        _error = 'Save failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Save failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===========================
    // Build the screen
    // ===========================
    return Scaffold(
      // ===========================
      // App Bar
      // ===========================
      appBar: AppBar(
        title: const Text('Complete Store Profile'),

        // Profile icon (top-right) → opens ProfilePage for logout
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
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
          ),
        ],
      ),

      // ===========================
      // Body
      // ===========================
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'Enter your store details to finish setup.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // =============== Store Name (Required) ===============
              TextField(
                controller: _storeNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Store Name *',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              // =============== Store Number (Required) ===============
              TextField(
                controller: _storeNumberController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Store Number *',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              // =============== Street Address ===============
              TextField(
                controller: _streetController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              // =============== City ===============
              TextField(
                controller: _cityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'City',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              // =============== Province ===============
              TextField(
                controller: _provinceController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Province',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              // =============== Phone Number ===============
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                ),
              ),

              const SizedBox(height: 16),

              // =============== Error Message ===============
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              // =============== Success / Info Message ===============
              if (_message != null)
                Text(
                  _message!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              // =============== Save Button ===============
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
