// Cheffery - menu.dart

// This page is the main menu shown to authenticated users. UNDER CONSTRUCTION

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_router.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/providers/supabase_provider.dart';

import '../profile/profile.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  bool _loggingOut = false;

  final List<String> _categories = const [
    'Shakes',
    'Meals',
    'Snacks',
    'Juice',
    'On-the-go',
  ];
  int _selectedCategoryIndex = 0;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              // ====== Header (logo + search + profile + tabs) ======
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    // ===== Top row =====
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pop(); // goes back to Locations
                          },
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

                        const SizedBox(width: 2),

                        Image.asset(
                          'assets/logos/freshBlendzLogo.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              textAlignVertical: TextAlignVertical
                                  .center, // vertical centering
                              decoration: const InputDecoration(
                                // Search icon
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Colors.black54,
                                ),

                                hintText: 'What’s your flavor today?',
                                hintStyle: TextStyle(
                                  fontSize: 12, // hint text size
                                  color: Colors.black45,
                                ),

                                border: InputBorder.none,
                                isDense: true,

                                // controls overall vertical centering
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14, // typed text size
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

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

                    const SizedBox(height: 12),

                    // ===== Tabs =====
                    SizedBox(
                      height: 46,
                      child: Row(
                        children: List.generate(_categories.length, (index) {
                          final isSelected = index == _selectedCategoryIndex;

                          return Expanded(
                            child: InkWell(
                              onTap: () => setState(
                                () => _selectedCategoryIndex = index,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _categories[index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    height: 3,
                                    width: isSelected ? 28 : 0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ====== Page content area ======
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_loggingOut || user == null)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        Text(
                          user.email ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _loggingOut
                            ? null
                            : () async {
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: AppPadding.button,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.button,
                          ),
                        ),
                        child: _loggingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Logout'),
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
                      'POWERED BY',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'CHEFFERY',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
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
