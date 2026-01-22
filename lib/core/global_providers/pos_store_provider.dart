// Cheffery - store_phone_provider.dart
//
// Active menu store provider. Gives both phonenumber for logout, aswell as their id for the pos user checkout

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';

class ActiveStore {
  ActiveStore({required this.id, required this.phoneNumber});
  final String id; // uuid
  final String phoneNumber;
}

final activeStoreProvider = FutureProvider.autoDispose<ActiveStore?>((
  ref,
) async {
  ref.watch(authStateProvider);

  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = ref.read(supabaseProvider);

  final row = await supabase
      .from('stores')
      .select('id, store_phone_number')
      .eq('owner_user_id', user.id)
      .maybeSingle();

  if (row == null) return null;

  final storeId = row['id'] as String?;
  final phone = (row['store_phone_number'] as String?)?.trim();

  if (storeId == null || phone == null || phone.isEmpty) return null;

  return ActiveStore(id: storeId, phoneNumber: phone);
});

final activeStoreIdProvider = Provider<String?>((ref) {
  final storeAsync = ref.watch(activeStoreProvider);
  return storeAsync.maybeWhen(data: (s) => s?.id, orElse: () => null);
});

final storePhoneProvider = FutureProvider.autoDispose<String?>((ref) async {
  final store = await ref.watch(activeStoreProvider.future);
  return store?.phoneNumber;
});
