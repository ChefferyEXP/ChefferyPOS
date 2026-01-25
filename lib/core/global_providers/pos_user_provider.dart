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

/// Display name helper
final activePosUserDisplayNameProvider = Provider<String>((ref) {
  final name = ref.watch(activePosUserFirstNameProvider);
  return (name == null || name.trim().isEmpty) ? 'Guest' : name.trim();
});

/// Guest helper
final isGuestPosUserProvider = Provider<bool>((ref) {
  final phone = ref.watch(activePosUserPhoneProvider);
  return phone == null || phone.trim().isEmpty;
});
