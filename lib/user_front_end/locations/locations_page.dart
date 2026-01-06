import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/user_front_end/menu/menu.dart';
import 'package:v0_0_0_cheffery_pos/user_front_end/profile/profile.dart';

class OrderLocation {
  final String id;
  final String name;
  final String address;
  final String imageAsset;

  const OrderLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.imageAsset,
  });
}

class LocationsPage extends ConsumerWidget {
  const LocationsPage({super.key});

  static const List<OrderLocation> locations = [
    OrderLocation(
      id: 'loc1',
      name: 'FreshBlendz — Downtown',
      address: '123 King St W, Toronto, ON',
      imageAsset: 'assets/logos/freshBlendzLogo.png',
    ),
    OrderLocation(
      id: 'loc2',
      name: 'FreshBlendz — Oshawa',
      address: '55 Simcoe St N, Oshawa, ON',
      imageAsset: 'assets/logos/freshBlendzLogo.png',
    ),
    OrderLocation(
      id: 'loc3',
      name: 'FreshBlendz — Whitby',
      address: '200 Brock St S, Whitby, ON',
      imageAsset: 'assets/logos/freshBlendzLogo.png',
    ),
  ];

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
                        'Choose a location',
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

              // ===== Location tiles =====
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    return _LocationTile(
                      location: loc,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MenuPage()),
                        );
                      },
                    );
                  },
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

class _LocationTile extends StatelessWidget {
  final OrderLocation location;
  final VoidCallback onTap;

  const _LocationTile({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
              child: Image.asset(
                location.imageAsset,
                width: 110,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}
