// Cheffery - auth_controller.dart

// This page defines the AuthController, which manages all authentication-related actions such as login, sign-up, password reset, and logout using Supabase.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers/supabase_provider.dart';

// UI state model for loading + error + info message for the login screen.
class AuthUiState {
  final bool loading; // Indicates auth action in progress or not
  final String? message; // Success or information message
  final String? error; // Error message to display

  const AuthUiState({this.loading = false, this.message, this.error});

  const AuthUiState.idle()
    : this(); // Default idle state (not loading, no messages)

  AuthUiState copyWith({bool? loading, String? message, String? error}) {
    //Create mutable AuthUiState
    return AuthUiState(
      loading: loading ?? this.loading,
      message: message,
      error: error,
    );
  }
}

// Riverpod notifier that manages authentication actions and UI state
class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState.idle(); //Initial state when provider is first created

  SupabaseClient get _supabase =>
      ref.read(supabaseProvider); // Access supabase client from provider

  void clearMessages() {
    state = state.copyWith(
      message: null,
      error: null,
    ); //Clear any error or success messages
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(
      loading: true,
      error: null,
      message: null,
    ); //Start loading and reset messages

    // Ensure both email and password are provided
    if (email.trim().isEmpty) {
      state = state.copyWith(loading: false, error: 'Please enter your email.');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Please enter your password.',
      );
      return;
    }

    try {
      final resp = await _supabase.auth.signInWithPassword(
        //Attempt login with supabase
        email: email.trim(), //Trim whitespace on email
        password: password,
      );

      // If no session returned, return login failed
      if (resp.session == null) {
        state = state.copyWith(
          loading: false,
          error: 'Login failed. Please check your email/password.',
        );
        return;
      }

      state = state.copyWith(loading: false); // Login Successful, stop loading
    } on AuthException catch (e) {
      state = state.copyWith(
        loading: false,
        error: _customAuthError(e.message),
      ); //Handle supabase auth error
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: "Unhandled Error (DEBUG): ${e.toString}",
      ); // Handle unexpected errors
    }
  }

  // Custom error messages for login
  String _customAuthError(String message) {
    final m = message.toLowerCase();

    if (m.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (m.contains('too many requests') || m.contains('rate limit')) {
      return 'Too many attempts. Please wait a bit and try again.';
    }
    if (m.contains('network') ||
        m.contains('socket') ||
        m.contains('timeout')) {
      return 'Network error. Check your connection and try again.';
    }

    // Fallback error to prevent sensitive error messages from supabase
    return 'Login failed. Please try again.';
  }

  // LOGOUT Functionality
  Future<void> logout() async {
    state = state.copyWith(
      loading: true,
      error: null,
      message: null,
    ); //Start loading and reset messages

    try {
      await _supabase.auth.signOut(); //Sign the user out
      state = state.copyWith(loading: false); // Stop loading after logout
    } on AuthException catch (e) {
      state = state.copyWith(
        loading: false,
        error: "Supabase Error (DEBUG): ${e.message}",
      ); //Handle supabase error
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: "Unhandled Error (DEBUG): ${e.toString}",
      ); //Handle unexpected errors
    }
  }

  //Puts error message on UI
  void setError(String message) {
    state = state.copyWith(loading: false, error: message, message: null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthUiState>(
  //Public provider exposed to the UI
  AuthController.new, //Creates AuthController instance
);
