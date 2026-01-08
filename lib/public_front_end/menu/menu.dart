// Cheffery - menu.dart

// This page is the main menu shown to authenticated users.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_router.dart';
import 'package:v0_0_0_cheffery_pos/auth/auth_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_providers.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_page.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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

    final cartCount = ref.watch(cartCountProvider);
    final cartDisplay = cartCount > 99 ? '99+' : cartCount.toString();

    return Scaffold(
      key: _scaffoldKey,

      // Menu cart slider
      endDrawer: _CartSlideOver(
        cartCount: cartCount,
        onGoToCart: () {
          // 1) close drawer
          Navigator.of(context).pop();

          // 2) go to cart page
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CartPage()));
        },
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAEEA00), Color(0xFF00C853)],
          ),
        ),

        // Top menu bar
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back arrow
                        InkWell(
                          onTap: () => Navigator.maybePop(context),
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

                        // Business logo
                        Image.asset(
                          'assets/logos/freshBlendzLogo.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(width: 10),

                        // Search Bar
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
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                hintText: 'What\'s your flavor today?',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black45,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14, height: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Shopping cart
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white.withOpacity(0.95),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      cartDisplay,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Menu Categories
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

              // ======================= BODY =================================
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
                        child: const Text('Logout'),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: _loggingOut
                            ? null
                            : () {
                                ref.read(cartCountProvider.notifier).state++;
                              },
                        child: const Text('Add to Cart'),
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

// ================= Menu Cart Slideover handler ==============
class _CartSlideOver extends StatelessWidget {
  const _CartSlideOver({required this.cartCount, required this.onGoToCart});

  final int cartCount;
  final VoidCallback onGoToCart;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width * 0.40;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          bottomLeft: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Cart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Items: $cartCount',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Text(
                    'Cart items will show here later.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onGoToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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
