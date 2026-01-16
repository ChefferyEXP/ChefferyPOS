// Cheffery - account_context_provider.dart

// This page is what determines what role the user is, and will affect where the auth router navigates them. For now, just store and admin

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';

// ===========================
// Models (Either admin or store role)
// ===========================
enum AccountRole { admin, store }

class AccountContext {
  final AccountRole role;

  /// True if the store has ALL required fields filled in
  final bool storeProfileCompleted;

  /// True if a row exists in stores for this store user.
  final bool storeRowExists;

  const AccountContext({
    required this.role,
    required this.storeProfileCompleted,
    required this.storeRowExists,
  });
}

// ===========================
// Provider: fetch role and store profile status
// ===========================
final accountContextProvider = FutureProvider.autoDispose<AccountContext?>((
  ref,
) async {
  // Depend on auth state so this provider refreshes when users login/logout
  ref.watch(authStateProvider);

  // Read current logged-in user from provider
  final user = ref.watch(currentUserProvider);

  // If no user, no context
  if (user == null) return null;

  final supabase = Supabase.instance.client;

  // ===========================
  // 1) Fetch role from account_details
  // ===========================
  final accountRow = await supabase
      .from('account_details')
      .select('role')
      .eq('user_id', user.id)
      .maybeSingle();

  if (accountRow == null) //Make sure there are account details
  {
    return null;
  }

  final roleStr = (accountRow['role'] as String).toLowerCase();
  final role = roleStr == 'admin' ? AccountRole.admin : AccountRole.store;

  // ===========================
  // Admin: storeProfileCompleted not matter
  // ===========================
  if (role == AccountRole.admin) {
    return const AccountContext(
      role: AccountRole.admin,
      storeProfileCompleted: true,
      storeRowExists: true,
    );
  }

  // ===========================
  // 2) If store, fetch row from stores table
  // ===========================
  final storeRow = await supabase
      .from('stores')
      .select(
        'store_name, store_number, store_street_address, store_city, store_province, store_phone_number',
      )
      .eq('owner_user_id', user.id)
      .maybeSingle();

  // If no store row, treat as NOT completed and route to setup.
  if (storeRow == null) {
    return const AccountContext(
      role: AccountRole.store,
      storeProfileCompleted: false,
      storeRowExists: false,
    );
  }

  // ===========================
  // 3) get profile complete by checking if required data exists
  // ===========================
  bool isFilled(String? v) => v != null && v.trim().isNotEmpty;

  // Required fields - Mechanically enforced on store setup and database to require all store input fields
  final completed =
      isFilled(storeRow['store_name'] as String?) &&
      isFilled(storeRow['store_number'] as String?);

  return AccountContext(
    role: AccountRole.store,
    storeProfileCompleted: completed,
    storeRowExists: true,
  );
});
