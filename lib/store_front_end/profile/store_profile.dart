// Cheffery - store_profile.dart
//
// This page is the stores profile. It allows them to view store information, aswell as logout.
// For now, they cannot edit any of their data, but potentially in a future interation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/auth/auth_router.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/store_providers/store_info_provider.dart';

class StoreProfilePage extends ConsumerStatefulWidget {
  const StoreProfilePage({super.key});

  @override
  ConsumerState<StoreProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<StoreProfilePage> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final supabase = ref.read(supabaseProvider);

    final storeAsync = ref.watch(storeInfoProvider);

    // Email prefix fallback for name
    final email = user?.email ?? '';
    final emailPrefix = (email.contains('@') ? email.split('@').first : email)
        .trim();

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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ===== Top bar  =====
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF2A2D34),
                elevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== Scrollable content =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),

                      // ===== Profile header =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                54,
                                16,
                                18,
                              ),
                              decoration: BoxDecoration(
                                // same premium dark card style
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3A3F48),
                                    Color(0xFF2A2F37),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
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
                                  // Store Name if present, else email prefix
                                  storeAsync.when(
                                    loading: () => Text(
                                      emailPrefix.isEmpty
                                          ? 'Loading…'
                                          : emailPrefix,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      emailPrefix.isEmpty
                                          ? 'Your Name'
                                          : emailPrefix,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    data: (store) {
                                      final storeName =
                                          (store?.storeName
                                                  ?.trim()
                                                  .isNotEmpty ??
                                              false)
                                          ? store!.storeName!.trim()
                                          : (emailPrefix.isEmpty
                                                ? 'Your Name'
                                                : emailPrefix);

                                      return Text(
                                        storeName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 6),

                                  // Email stays where it is
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Avatar badge
                            Positioned(
                              top: -22,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: CircleAvatar(
                                  radius: 34,
                                  backgroundColor: const Color(0xFF2D3138),
                                  child: const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===== Store details card =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3A3F48), Color(0xFF2A2F37)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: storeAsync.when(
                            loading: () => const _StoreDetailsLoading(),
                            error: (e, _) => const _StoreDetailsEmpty(
                              text: 'No store info yet',
                            ),
                            data: (store) {
                              final number = store?.storeNumber?.trim() ?? '';
                              final street = store?.streetAddress?.trim() ?? '';
                              final city = store?.city?.trim() ?? '';
                              final province = store?.province?.trim() ?? '';
                              final phone = store?.phoneNumber?.trim() ?? '';

                              final hasAny =
                                  number.isNotEmpty ||
                                  street.isNotEmpty ||
                                  city.isNotEmpty ||
                                  province.isNotEmpty ||
                                  phone.isNotEmpty;

                              if (!hasAny) {
                                return const _StoreDetailsEmpty(
                                  text: 'No store info yet',
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Store Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    icon: Icons.confirmation_number_outlined,
                                    label: 'Store Number',
                                    value: number.isEmpty ? '—' : number,
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'Street',
                                    value: street.isEmpty ? '—' : street,
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: Icons.location_city_outlined,
                                    label: 'City',
                                    value: city.isEmpty ? '—' : city,
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: Icons.map_outlined,
                                    label: 'Province',
                                    value: province.isEmpty ? '—' : province,
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Phone',
                                    value: phone.isEmpty ? '—' : phone,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===== Account actions (only logout for now) =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3A3F48), Color(0xFF2A2F37)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
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
                              const Text(
                                'Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 8),
                              _ActionTile(
                                icon: Icons.logout,
                                title: _loggingOut ? 'Logging out…' : 'Logout',
                                subtitle: 'Sign out of your account',
                                isDestructive: true,
                                onTap: () async {
                                  if (_loggingOut) return;
                                  setState(() => _loggingOut = true);

                                  if (!context.mounted) return;

                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthRouter(),
                                    ),
                                    (route) => false,
                                  );

                                  await supabase.auth.signOut();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===== Footer =====
                      const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
            ],
          ),
        ),
      ),
    );
  }
}

// Display while store details are loading
class _StoreDetailsLoading extends StatelessWidget {
  const _StoreDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Loading store info…',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Display when store details are empty (should only be shown one first login if profile is selected before its created)
class _StoreDetailsEmpty extends StatelessWidget {
  final String text;
  const _StoreDetailsEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.info_outline,
            color: Colors.white70,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget of actual information rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===== Action buttons for profile =====
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isDestructive
        ? Colors.red.withOpacity(0.16)
        : Colors.white.withOpacity(0.10);

    final iconColor = isDestructive ? Colors.redAccent : Colors.white70;

    final titleColor = isDestructive ? Colors.redAccent : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
