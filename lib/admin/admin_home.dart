// Work in progress admin panel

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/profile/profile.dart';

// ===========================
// Admin Home Page
// ===========================
class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // ===========================
      // App Bar
      // ===========================
      appBar: AppBar(
        title: const Text('Admin Home'),

        // Profile icon at top-right (opens ProfilePage)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.95),
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

      // ===========================
      // Body
      // ===========================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =============== Header ===============
            const Text(
              'Admin Controls',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // =============== Add Store Button ===============
            ElevatedButton(
              onPressed: () {
                // TODO: wire to Edge Function
              },
              child: const Text('Add Store'),
            ),
          ],
        ),
      ),
    );
  }
}
