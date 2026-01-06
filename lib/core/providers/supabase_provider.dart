// Cheffery - supabase_provider.dart

// This provider exposes the globally initialized Supabase client so it can be safely and consistently accessed everywhere in the app with Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provide a single, shared, SupabaseClient instance to the entire app with Riverpod
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
