import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active POS customer (row from `pos_users`)
final activePosUserIdProvider = StateProvider<int?>((ref) => null);

/// Cached phone number (E.164)
final activePosUserPhoneProvider = StateProvider<String?>((ref) => null);

/// Cached first name (optional)
final activePosUserFirstNameProvider = StateProvider<String?>((ref) => null);

/// Convenience: true if a customer is selected
final hasActivePosUserProvider = Provider<bool>((ref) {
  return ref.watch(activePosUserIdProvider) != null;
});
