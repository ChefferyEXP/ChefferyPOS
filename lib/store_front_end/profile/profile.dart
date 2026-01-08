// Work in progress profile page

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/auth/auth_router.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/providers/supabase_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final supabase = ref.read(supabaseProvider);

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
                    const SizedBox(width: 10),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== Profile header =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Name',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar badge
                    const Positioned(
                      top: -20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== Action card for each option on profile =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _ActionTile(
                        icon: Icons.email_outlined,
                        title: 'Change Email',
                        subtitle: 'Update your login email',
                        onTap: () {
                          // TODO: Navigator.push(context,
                          // MaterialPageRoute(builder: (_) => const EmailChangePage()));
                        },
                      ),

                      _ActionTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () {
                          // TODO: Navigator.push(context,
                          // MaterialPageRoute(builder: (_) => const PasswordChangePage()));
                        },
                      ),

                      const SizedBox(height: 8),

                      _ActionTile(
                        icon: Icons.logout,
                        title: 'Logout',
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

              const Spacer(),

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
    final color = isDestructive ? Colors.red : Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : Colors.black12,
              child: Icon(icon, color: color, size: 20),
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
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
