import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';

// ===========================
// Models (Either admin or store role)
// ===========================
enum AccountRole { admin, store }

class AccountContext {
  final AccountRole role;
  final bool
  storeProfileCompleted; //Check if the store has entered information yet (First login)

  const AccountContext({
    required this.role,
    required this.storeProfileCompleted,
  });
}

// ===========================
// Provider: fetch role + store profile status
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
  // 2) If store, fetch profile_completed from stores table
  // ===========================
  if (role == AccountRole.store) {
    final storeRow = await supabase
        .from('stores')
        .select('profile_completed')
        .eq('owner_user_id', user.id)
        .maybeSingle();

    final completed = (storeRow?['profile_completed'] as bool?) ?? false;

    return AccountContext(role: role, storeProfileCompleted: completed);
  }

  // Admin: storeProfileCompleted not matter
  return const AccountContext(
    role: AccountRole.admin,
    storeProfileCompleted: true,
  );
});
