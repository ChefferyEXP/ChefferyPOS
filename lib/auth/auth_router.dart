// Cheffery - auth_router.dart
//
// This widget acts as the source for authentication based routing.
// It decides which screen to show the user based on authentication state.
//
// Listens to Supabased auth state changes via riverpod
// Shows loading indicator while an auth state is being resolved
// Shows an error screen if auth fails
// Route to menu if loggin in, Welcome page otherwise

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../public/welcome/welcome.dart';

import 'package:v0_0_0_cheffery_pos/user_front_end/home/home_page.dart';

import 'auth_provider.dart';

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

      // Once auth state data is availible
      data: (_) {
        final user = ref.watch(currentUserProvider); //Read current user
        return user != null
            ? const HomePage()
            : const WelcomePage(); //If user exists take to menu, otherwise return to welcome.
      },
    );
  }
}
