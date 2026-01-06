// Cheffery - main.dart
/*
  main.dart is the entry point of the application and is responsible for bootstrapping all core services before the UI render. Flutter bindings, environment variables, 
  and the Supabase client are initialized. The app is wrapped in a ProviderScope to enable Riverpod state management globally. Root MaterialApp is defined to
  apply the global theme, and delegate initial navigation to AuthRouter.
*/

/* 
Why Riverpod? 
  Riverpod is used because it provides a clean, scalable, and testable way to manage state and dependencies without relying on widget context. It makes authentication, 
  global services, and UI state predictable and easy to maintain as the app grows.
*/

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/public/login_signup_forgotPass/login.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_router.dart';
import 'package:v0_0_0_cheffery_pos/user_front_end/menu/menu.dart';
import 'package:v0_0_0_cheffery_pos/user_front_end/locations/locations_page.dart';
import 'package:v0_0_0_cheffery_pos/user_front_end/home/home_page.dart';
import 'package:v0_0_0_cheffery_pos/user_front_end/profile/profile.dart';

Future<void> main() async {
  //Ensures Flutter engine/bindings are ready before doing async work
  //Required for: Loading dotenv, init plugins, etc
  WidgetsFlutterBinding.ensureInitialized();

  //Load enviroment variables from .env
  await dotenv.load(fileName: '.env');

  // Initialize Supabase at app start
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  //ProviderScope is the root riverpod container
  //Required for: ref.watch, ref.read
  runApp(const ProviderScope(child: ChefferyPOS()));
}

class ChefferyPOS extends StatelessWidget {
  const ChefferyPOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //App title
      title: 'Cheffery POS',
      //Remove debug banner
      debugShowCheckedModeBanner: false,
      //Global theme
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),

      // Auth Router used to decide first screen shown when app started
      // not logged in = welcome page
      // Logged in = Menu
      home: const AuthRouter(), //Welcome page
      routes: {
        // Route for the login screen
        '/login': (context) => const LoginPage(),
        // Main logged in area route (menu)
        '/menu': (context) => const MenuPage(),
        // Locations page for location selection
        '/locations': (context) => const LocationsPage(),
        // Home page
        '/home': (context) => const HomePage(),
        // Profile Page
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
