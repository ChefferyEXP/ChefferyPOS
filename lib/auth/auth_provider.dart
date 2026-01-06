// Cheffery - auth_provider.dart

// This listens to Supabase authentication state cahnges and exposes them through RiverPod so the app can react to login and logout events. Also provides derived value
// for current user updating automatically whenever auth state changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/supabase_provider.dart';

// Stream provider to listen to supabase authentication state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange;
});

// Provider that exposes the current logged-in user
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});
