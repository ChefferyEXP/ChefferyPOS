// Cheffery - auth_router.dart
//
// This widget acts as the source for authentication based routing.
// It decides which screen to show the user based on authentication state.
//
// Listens to Supabased auth state changes via riverpod
// Shows loading indicator while an auth state is being resolved
// Shows an error screen if auth fails

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/auth/login.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/home/store_home_page.dart';
import 'package:v0_0_0_cheffery_pos/admin/admin_home.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/setup/store_setup.dart';
import 'package:v0_0_0_cheffery_pos/auth/account_context_provider.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';

// Consumer widget to access riverpod providers
class AuthRouter extends ConsumerWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication state
    final authAsync = ref.watch(authStateProvider);

    // While Supabase determines auth state (startup or session restore) show loading circle
    return authAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      // If an error occurs while listening to auth state
      error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),

      // Once auth state data is available
      data: (_) {
        final user = ref.watch(currentUserProvider); // Read current user

        // If no user, show login page
        if (user == null) return const LoginPage();

        // ===========================
        // Fetch role + store setup status
        // ===========================
        final ctxAsync = ref.watch(accountContextProvider);

        return ctxAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),

          error: (e, _) =>
              Scaffold(body: Center(child: Text('Account context error: $e'))),

          data: (ctx) {
            // If ctx is null, something is missing (trigger/table mismatch)
            if (ctx == null) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Account Misconfigured',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // ===========================
            // Route: Admin
            // ===========================
            if (ctx.role == AccountRole.admin) {
              return const AdminHomePage();
            }

            // ===========================
            // Route: Store
            // - If profile not completed -> setup screen
            // - Else -> normal store home
            // ===========================
            if (!ctx.storeProfileCompleted) {
              return const StoreSetupPage();
            }

            return const StoreHomePage();
          },
        );
      },
    );
  }
}
