// Cheffery - store_phone_provider.dart
//
//Store phone provider (used to logout on the public side)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';

final storePhoneProvider = FutureProvider.autoDispose<String?>((ref) async {
  ref.watch(authStateProvider);

  // Get current user (store)
  final user = ref.watch(currentUserProvider);

  // Null check
  if (user == null) return null;

  // Get supabase
  final supabase = ref.read(supabaseProvider);

  // Get the phone number
  final row = await supabase
      .from('stores')
      .select('store_phone_number')
      .eq('owner_user_id', user.id)
      .maybeSingle();

  final phone = (row?['store_phone_number'] as String?)?.trim();
  return (phone == null || phone.isEmpty) ? null : phone;
});
