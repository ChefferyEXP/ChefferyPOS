// Cheffery - admin_home.dart

// Work in progress admin panel
// Idea: Be able to view all stores using cheffery pos. Be able to add stores through the software. Be able to maybe reset passwords or w/e aswell.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v0_0_0_cheffery_pos/admin/admin_profile.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hard-coded stores for now
    final stores = <_AdminStoreCardData>[
      const _AdminStoreCardData(
        name: 'FreshBlendz — Downtown',
        address: '123 Test St W, Toronto, ON',
        phone: '+1 (416) 123-4567',
        owner: 'Owner 1 Name',
      ),
      const _AdminStoreCardData(
        name: 'FreshBlendz — North',
        address: '71 Simcoe St N, Oshawa, ON',
        phone: '+1 (905) 123-4567',
        owner: 'Owner 2 Name',
      ),
      const _AdminStoreCardData(
        name: 'FreshBlendz — South',
        address: '88 Lakeshore Rd, Mississauga, ON',
        phone: '+1 (289) 555-0199',
        owner: 'Owner 3 Name',
      ),
    ];

    return Scaffold(
      // White dashboard background
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text(
          'Admin Home',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.6,
        surfaceTintColor: Colors.white,

        // Profile icon at top-right (opens ProfilePage)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF3F4F6),
                child: const Icon(
                  Icons.person,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Container(
        // ===== Clean modern white background =====
        color: const Color(0xFFF9FAFB), // soft off-white
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== My App Stores =====
                const Text(
                  'My App Stores',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // ===== Store list =====
                _GlassCard(
                  child: Column(
                    children: [
                      ...List.generate(stores.length, (i) {
                        final s = stores[i];
                        return Column(
                          children: [
                            _SelectableStoreRow(
                              store: s,
                              onTap: () {
                                // TODO: update selected store provider / state later
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Selected: ${s.name}'),
                                    duration: const Duration(milliseconds: 900),
                                  ),
                                );
                              },
                            ),
                            if (i != stores.length - 1)
                              Divider(
                                height: 18,
                                thickness: 1,
                                color: Colors.black.withOpacity(0.06),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ===== Admin Controls =====
                const Text(
                  'Admin Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add Stores',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: wire to Edge Function
                          },
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ).copyWith(
                                overlayColor: WidgetStatePropertyAll(
                                  Colors.white.withOpacity(0.10),
                                ),
                              ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_business, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Add Store',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================
// UI helpers
// ===========================

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SelectableStoreRow extends StatelessWidget {
  final _AdminStoreCardData store;
  final VoidCallback onTap;

  const _SelectableStoreRow({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _MiniChip(icon: Icons.phone, text: store.phone),
                      _MiniChip(icon: Icons.person_outline, text: store.owner),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple data holder for hard-coded store list
class _AdminStoreCardData {
  final String name;
  final String address;
  final String phone;
  final String owner;

  const _AdminStoreCardData({
    required this.name,
    required this.address,
    required this.phone,
    required this.owner,
  });
}
