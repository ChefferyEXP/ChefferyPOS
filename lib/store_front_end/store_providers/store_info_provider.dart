// Cheffery - store_info_provider.dart
//
// This fetches all of the store information on every store login.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';

// ===========================
// Store model
// ===========================
class StoreInfo {
  final String? storeName;
  final String? storeNumber;
  final String? streetAddress;
  final String? city;
  final String? province;
  final String? phoneNumber;

  const StoreInfo({
    required this.storeName,
    required this.storeNumber,
    required this.streetAddress,
    required this.city,
    required this.province,
    required this.phoneNumber,
  });

  factory StoreInfo.fromRow(Map<String, dynamic> row) {
    return StoreInfo(
      storeName: row['store_name'] as String?,
      storeNumber: row['store_number'] as String?,
      streetAddress: row['store_street_address'] as String?,
      city: row['store_city'] as String?,
      province: row['store_province'] as String?,
      phoneNumber: row['store_phone_number'] as String?,
    );
  }

  bool get hasAnyInfo {
    final n = storeName?.trim() ?? '';
    final num = storeNumber?.trim() ?? '';
    final st = streetAddress?.trim() ?? '';
    final c = city?.trim() ?? '';
    final p = province?.trim() ?? '';
    final ph = phoneNumber?.trim() ?? '';
    return n.isNotEmpty ||
        num.isNotEmpty ||
        st.isNotEmpty ||
        c.isNotEmpty ||
        p.isNotEmpty ||
        ph.isNotEmpty;
  }
}

// ===========================
// Provider: fetch store info for current user
// ===========================
final storeInfoProvider = FutureProvider.autoDispose<StoreInfo?>((ref) async {
  ref.watch(authStateProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = Supabase.instance.client;

  final row = await supabase
      .from('stores')
      .select(
        'store_name, store_number, store_street_address, store_city, store_province, store_phone_number',
      )
      .eq('owner_user_id', user.id)
      .maybeSingle();

  if (row == null) return null;

  return StoreInfo.fromRow(row);
});
