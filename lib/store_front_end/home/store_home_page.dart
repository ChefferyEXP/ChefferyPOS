// Cheffery - store_home_page.dart
//
// This page is designed to be the home page for a store user.
// Will allow them to edit to their menu, and view their store analytics (to come in future interation)
// Also allows them to go into POS mode for their store (Working mostly .... Need to add flag to keep app in POS mode on restart .. WIP on that part)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/store_front_end/live/go_live_public.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/profile/store_profile.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/store_providers/store_info_provider.dart';

class StoreHomePage extends ConsumerWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeInfoProvider);

    return Scaffold(
      body: Container(
        // ===== Background =====
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2D34), // soft charcoal
              Color(0xFF1F2329), // deep slate
              Color(0xFF181C21), // muted dark
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Top bar =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StoreProfilePage(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        // slightly darker pill but still readable
                        backgroundColor: const Color(0xFF2D3138),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Main content =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ===== Welcome / Branding Card =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3A3F48), // lighter slate
                              Color(0xFF2A2F37), // darker slate
                            ],
                          ),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'WELCOME',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white70,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ===== Logos + Store Name =====
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left logo (Cheffery)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/logos/cheffery.png',
                                        height: 90, // unchanged
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),

                                // Store name
                                storeAsync.when(
                                  loading: () => const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Store…',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Loading…',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  error: (e, _) => const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Store',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Unable to load',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  data: (store) {
                                    final storeNumber =
                                        (store?.storeNumber
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                        ? store!.storeNumber!.trim()
                                        : '—';

                                    final storeName =
                                        (store?.storeName?.trim().isNotEmpty ??
                                            false)
                                        ? store!.storeName!.trim()
                                        : 'Store Profile';

                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Store $storeNumber',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          storeName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white70,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                // Right logo (FreshBlendz)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/logos/freshBlendzLogo.png',
                                        height: 150, // unchanged
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ===== Analytics and Menu actio card buttons =====
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.insights_outlined,
                              title: 'My Analytics',
                              subtitle: 'Sales & trends',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.restaurant_menu,
                              title: 'My Menu',
                              subtitle: 'Items & pricing',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ===== Primary POSButton =====
                      _PrimaryPOSButton(
                        label: 'Enter POS Mode',
                        subtitle: 'Start taking orders',
                        icon: Icons.point_of_sale_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GoLivePublic(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ===== Footer =====
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
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
                    SizedBox(height: 6),
                    Text(
                      'Cheffery POS',
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

// ===========================
// Analytics and Menu action card
// ===========================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          // dark card that still feels “premium”
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A3F48), Color(0xFF2A2F37)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20, // unchanged
              backgroundColor: Colors.white.withOpacity(0.08),
              child: Icon(icon, color: Colors.white70, size: 22),
            ),
            const SizedBox(height: 14), // unchanged
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================
//  Go to POS button
// ===========================
class _PrimaryPOSButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryPOSButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ), // unchanged
        decoration: BoxDecoration(
          // slightly brighter POSButton so it stands out on dark bg
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A505B), Color(0xFF343A44)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24, // unchanged
              backgroundColor: Colors.white.withOpacity(0.10),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }
}
