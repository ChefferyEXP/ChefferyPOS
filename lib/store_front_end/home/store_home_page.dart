// Work in progress - Need to over haul this page

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/store_front_end/live/go_live_public.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/profile/profile.dart';

class StoreHomePage extends ConsumerWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFAEEA00), // yellowish-green
              Color(0xFF00C853), // green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Top bar =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.95),
                        child: const Icon(
                          Icons.person,
                          color: Colors.black54,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Main content =====
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //  My app logo
                      Image.asset(
                        'assets/logos/cheffery.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Cheffery',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 16),

                      //  Powered by
                      const Text(
                        'Powered By',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 0.6,
                        ),
                      ),

                      const SizedBox(height: 16),

                      //  FreshBlendz logo
                      Image.asset(
                        'assets/logos/freshBlendzLogo.png',
                        height: 110,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 8),

                      // FreshBlendz title
                      const Text(
                        'FreshBlendz',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Get Started button
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GoLivePublic(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Tap to Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== Footer =====
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Powered By',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cheffery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
