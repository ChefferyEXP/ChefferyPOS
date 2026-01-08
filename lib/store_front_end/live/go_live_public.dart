import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/store_front_end/profile/profile.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/welcome/welcome.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';

// ============== Page to convert to customer front end ==================
class GoLivePublic extends ConsumerWidget {
  const GoLivePublic({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAEEA00), Color(0xFF00C853)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Header =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back arrow
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Image.asset(
                      'assets/logos/freshBlendzLogo.png',
                      height: 52,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Configure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // Profile icon
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

              // ===== Go to public button =====
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WelcomePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: AppPadding.button,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.button,
                          ),
                        ),
                        child: const Text('Go Into Public POS'),
                      ),
                    ),
                  ),
                ),
              ),

              // ===== Footer =====
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
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
