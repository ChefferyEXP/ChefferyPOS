// Cheffery - menu.dart

// This is the main menu for POS users. The store must first be logged into access this.
// Requires users phone number and name to get here
// Displays the products for that store from the database
// Further allows the user to look at the item, see choose varients, and add to cart.

// NOTE: Due to loading times, the way it loads is by loading everything at menu load time, and caching it. It will load the first category selected first, to give the illusion
//       of the quickest loading time possible. If a user jumps to other product categories immediately, it will show a loading circle until they can be fetched and displayed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/core/global_widgets/confirm_dialog_widget.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';

import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_page.dart';

import 'package:v0_0_0_cheffery_pos/public_front_end/menu/cart_slider_widget.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/menu/menu_data_source.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/menu/menu_models.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/menu/menu_item_card_widget.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/menu/product_variations.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_provider.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  late final MenuDataSource _menuDataStore;

  String _itemKey(MenuCardItem it) =>
      '${it.name.trim()}||${it.subtitle.trim()}||${(it.image_uri ?? '').trim()}';

  int _selectedCategoryIndex = 0;
  Future<List<MenuCategoryTab>>? _categoriesFuture;

  // ===== caching + background preloading bool =====
  bool _didKickOffPrefetch = false;

  // =============================
  // Initial-load / caching flags
  // =============================
  bool _initialLoading = true;

  final Map<int, bool> _catLoading = {}; // categoryId -> loading
  final Map<int, String?> _catError = {}; // categoryId -> error (optional)

  // only show when fully loaded
  List<MenuCardItem> _visibleItems = const [];

  // cache of ALL items by categoryId (already signed + precached)
  final Map<int, List<MenuCardItem>> _itemsByCategory = {};

  // in-flight fetches to avoid duplicate requests
  final Map<int, Future<List<MenuCardItem>>> _inflightByCategory = {};

  bool _loadingSelected = false;
  String? _loadError;

  // cached categories after first load
  List<MenuCategoryTab>? _lastCategories;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_applyLocalSearch);

    final supabase = ref.read(supabaseProvider);
    _menuDataStore = MenuDataSource(supabase);

    _categoriesFuture = _menuDataStore.fetchCategoriesForCurrentStoreMenu();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyLocalSearch);
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // Search uses the cached items to increase search speed, rather than pulling from database
  // =========================================================
  void _applyLocalSearch() => _rebuildVisibleItems();

  void _rebuildVisibleItems() {
    final cats = _lastCategories;
    if (cats == null || cats.isEmpty) return;

    final selected = cats[_selectedCategoryIndex.clamp(0, cats.length - 1)];
    final cached =
        _itemsByCategory[selected.categoryId] ?? const <MenuCardItem>[];

    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _visibleItems = cached);
      return;
    }

    final filtered = cached.where((it) {
      return it.name.toLowerCase().contains(q) ||
          it.subtitle.toLowerCase().contains(q) ||
          it.calories.toLowerCase().contains(q) ||
          it.highlighted_feature.toLowerCase().contains(q);
    }).toList();

    setState(() => _visibleItems = filtered);
  }

  // =========================================================
  // Tab switching uses cache; fetch only if not loaded yet
  // =========================================================
  void _onCategoryTap(int index) async {
    final cats = _lastCategories;
    if (cats == null || cats.isEmpty) return;

    final safeIndex = index.clamp(0, cats.length - 1);
    final selected = cats[safeIndex];
    final catId = selected.categoryId;

    if (_itemsByCategory.containsKey(catId)) {
      setState(() {
        _selectedCategoryIndex = safeIndex;
        _loadError = null;
        _loadingSelected = false;
      });
      _rebuildVisibleItems();
      return;
    }

    setState(() {
      _selectedCategoryIndex = safeIndex;
      _loadError = null;
      _loadingSelected = true;
      _visibleItems = const [];
    });

    // Race guard: if user taps again while we load,
    // only the latest tap should be allowed to publish results.
    final tapToken = catId;

    try {
      await _ensureCategoryLoaded(selected, showSpinner: false);
      if (!mounted) return;

      // If user switched tabs while loading, do nothing.
      final currentCats = _lastCategories;
      if (currentCats == null || currentCats.isEmpty) return;
      final currentSelected =
          currentCats[_selectedCategoryIndex.clamp(0, currentCats.length - 1)];

      if (currentSelected.categoryId != tapToken) return;

      setState(() => _loadingSelected = false);
      _rebuildVisibleItems();
    } catch (e) {
      if (!mounted) return;

      final currentCats = _lastCategories;
      if (currentCats == null || currentCats.isEmpty) return;
      final currentSelected =
          currentCats[_selectedCategoryIndex.clamp(0, currentCats.length - 1)];
      if (currentSelected.categoryId != tapToken) return;

      setState(() {
        _loadingSelected = false;
        _loadError = e.toString();
        _visibleItems = const [];
      });
    }
  }

  // =========================================================
  // One-time initial load: show first category ASAP then prefetch rest
  // =========================================================
  void _kickOffInitialLoads(List<MenuCategoryTab> categories) {
    if (_didKickOffPrefetch) return;
    _didKickOffPrefetch = true;

    _lastCategories = categories;

    setState(() {
      _initialLoading = true;
      _loadError = null;
    });

    final first =
        categories[_selectedCategoryIndex.clamp(0, categories.length - 1)];

    _ensureCategoryLoaded(first, showSpinner: true)
        .then((_) {
          if (!mounted) return;

          _rebuildVisibleItems();

          setState(() {
            _initialLoading = false;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _prefetchAllOtherCategories(
              categories,
              skipCategoryId: first.categoryId,
            );
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() {
            _initialLoading = false;
            _loadError = e.toString();
          });
        });
  }

  Future<void> _prefetchAllOtherCategories(
    List<MenuCategoryTab> categories, {
    required int skipCategoryId,
  }) async {
    for (final tab in categories) {
      if (!mounted) return;
      if (tab.categoryId == skipCategoryId) continue;
      if (_itemsByCategory.containsKey(tab.categoryId)) continue;

      await _ensureCategoryLoaded(tab, showSpinner: false);
    }
  }

  Future<void> _ensureCategoryLoaded(
    MenuCategoryTab tab, {
    required bool showSpinner,
  }) async {
    final categoryId = tab.categoryId;

    if (_itemsByCategory.containsKey(categoryId)) return;

    bool isSelectedCategory() {
      final cats = _lastCategories;
      if (cats == null || cats.isEmpty) return false;
      final selected = cats[_selectedCategoryIndex.clamp(0, cats.length - 1)];
      return selected.categoryId == categoryId;
    }

    // already fetching
    final inflight = _inflightByCategory[categoryId];
    if (inflight != null) {
      _catLoading[categoryId] = true;
      _catError[categoryId] = null;

      if (showSpinner && isSelectedCategory() && mounted) {
        setState(() {
          _loadingSelected = true;
          _loadError = null;
        });
      }

      try {
        final items = await inflight;
        if (!mounted) return;
        _itemsByCategory[categoryId] = items;
        _catError[categoryId] = null;
      } catch (e) {
        if (!mounted) return;
        _catError[categoryId] = e.toString();
        if (showSpinner && isSelectedCategory()) {
          setState(() => _loadError = e.toString());
        }
      } finally {
        _catLoading[categoryId] = false;
        if (showSpinner && isSelectedCategory() && mounted) {
          setState(() => _loadingSelected = false);
        }
      }
      return;
    }

    _catLoading[categoryId] = true;
    _catError[categoryId] = null;

    if (showSpinner && isSelectedCategory() && mounted) {
      setState(() {
        _loadingSelected = true;
        _loadError = null;
      });
    }

    final fut = _menuDataStore.fetchMenuItemsForCategory(
      context: context,
      tab: tab,
    );

    _inflightByCategory[categoryId] = fut;

    try {
      final items = await fut;
      if (!mounted) return;
      _itemsByCategory[categoryId] = items;
      _catError[categoryId] = null;
    } catch (e) {
      if (!mounted) return;
      _catError[categoryId] = e.toString();
      if (showSpinner && isSelectedCategory()) {
        setState(() => _loadError = e.toString());
      }
    } finally {
      _inflightByCategory.remove(categoryId);
      _catLoading[categoryId] = false;

      if (showSpinner && isSelectedCategory() && mounted) {
        setState(() => _loadingSelected = false);
      }
    }
  }

  // =========================================================
  // OPTIONAL: call this when coming back from Variations/Cart to refresh any menu data if desired
  // =========================================================
  Future<void> refreshMenuData() async {
    if (!mounted) return;

    setState(() {
      _itemsByCategory.clear();
      _inflightByCategory.clear();
      _visibleItems = const [];
      _loadingSelected = false;
      _loadError = null;
      _didKickOffPrefetch = false;

      _initialLoading = true;
    });

    final categories = await _menuDataStore
        .fetchCategoriesForCurrentStoreMenu();

    if (!mounted) return;
    setState(() {
      _lastCategories = categories;
      if (_selectedCategoryIndex >= categories.length) {
        _selectedCategoryIndex = 0;
      }
    });

    if (categories.isNotEmpty) {
      _kickOffInitialLoads(categories);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===== Ensure a POS customer is selected (session guard) =====
    final posUserId = ref.watch(activePosUserIdProvider);

    if (posUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/get_user_phone');
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final isPhoneWidth = media.size.width < 600; // good practical breakpoint

    // Cart badge
    final cartCount = ref.watch(cartCountProvider);
    final cartDisplay = cartCount > 99 ? '99+' : cartCount.toString();

    // === Top bar sizing tweaks for mobile ===
    final logoHeight = isPhoneWidth ? 64.0 : 90.0;
    final searchHeight = isPhoneWidth ? 44.0 : 50.0;
    final searchHintFontSize = isPhoneWidth ? 12.0 : 16.0;
    final searchTextFontSize = isPhoneWidth ? 11.5 : 14.0;
    final searchIconSize = isPhoneWidth ? 18.0 : 20.0;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: CartSlideOver(
        cartCount: cartCount,
        onGoToCart: () async {
          Navigator.of(context).pop();
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
        child: SafeArea(
          child: Column(
            children: [
              // ===== Top bar + category tabs =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back arrow
                        InkWell(
                          onTap: () async {
                            final leave = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => ConfirmDialog(
                                title: 'Leave menu?',
                                message:
                                    'Are you sure you want to leave the menu?\n\nYour transaction will be voided.',
                                onConfirmText: 'Yes',
                                onCancelText: 'No',
                                primaryColor: AppColors.accent,
                                width: 620,
                                height: 380,
                              ),
                            );

                            if (leave == true && context.mounted) {
                              await ref.read(clearCartProvider)();

                              ref.read(activePosUserIdProvider.notifier).state =
                                  null;
                              ref
                                      .read(activePosUserPhoneProvider.notifier)
                                      .state =
                                  null;
                              ref
                                      .read(
                                        activePosUserFirstNameProvider.notifier,
                                      )
                                      .state =
                                  null;

                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/welcome',
                                (route) => false,
                              );
                            }
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

                        const SizedBox(width: 6),

                        // LOGO (smaller on phone)
                        SizedBox(
                          height: logoHeight,
                          child: Image.asset(
                            'assets/logos/freshBlendzLogo.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Search (smaller text on phone)
                        Expanded(
                          child: Container(
                            height: searchHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: searchIconSize,
                                  color: Colors.black54,
                                ),
                                hintText: 'What\'s your flavor today?',
                                hintStyle: TextStyle(
                                  fontSize: searchHintFontSize,
                                  color: Colors.black45,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: isPhoneWidth ? 10 : 12,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: searchTextFontSize,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: isPhoneWidth ? 12 : 20),

                        // Cart
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
                                radius: isPhoneWidth ? 22 : 26,
                                backgroundColor: Colors.white.withOpacity(0.95),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.black87,
                                  size: isPhoneWidth ? 22 : 24,
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
                    const SizedBox(height: 10),

                    // ===== Categories from DB =====
                    FutureBuilder<List<MenuCategoryTab>>(
                      future: _categoriesFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 46,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snap.hasError) {
                          return SizedBox(
                            height: 46,
                            child: Center(
                              child: Text(
                                'Failed to load categories.\n${snap.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }

                        final categories =
                            snap.data ?? const <MenuCategoryTab>[];
                        _lastCategories = categories;

                        if (categories.isEmpty) {
                          return const SizedBox(
                            height: 46,
                            child: Center(
                              child: Text(
                                'No categories yet.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }

                        if (_selectedCategoryIndex >= categories.length) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() => _selectedCategoryIndex = 0);
                          });
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _kickOffInitialLoads(categories);
                        });

                        final maxVisible = isLandscape ? 5 : 4;

                        if (categories.length <= maxVisible) {
                          // ===== Span full width (no scroll) =====
                          return SizedBox(
                            height: 46,
                            child: Row(
                              children: List.generate(categories.length, (
                                index,
                              ) {
                                final isSelected =
                                    index == _selectedCategoryIndex;
                                final label = categories[index].label;

                                return Expanded(
                                  child: InkWell(
                                    onTap: () => _onCategoryTap(index),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: isPhoneWidth
                                                  ? 15.5
                                                  : 17,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          height: 3,
                                          width: isSelected ? 28 : 0,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }

                        // ===== Too many categories -> scroll =====
                        return SizedBox(
                          height: 46,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: List.generate(categories.length, (
                                  index,
                                ) {
                                  final isSelected =
                                      index == _selectedCategoryIndex;
                                  final label = categories[index].label;

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isPhoneWidth ? 14 : 18,
                                    ),
                                    child: InkWell(
                                      onTap: () => _onCategoryTap(index),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: isPhoneWidth
                                                  ? 15.5
                                                  : 17,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            height: 3,
                                            width: isSelected ? 28 : 0,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== Products grid (uses cached _visibleItems) =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isLandscapeLocal = c.maxWidth > c.maxHeight;
                      final isPhoneWidthLocal = c.maxWidth < 600;

                      // Landscape: 5 columns
                      // Portrait: phone -> 2 columns, tablet -> 3 columns
                      final crossAxisCount = isLandscapeLocal
                          ? 5
                          : (isPhoneWidthLocal ? 2 : 3);

                      // Give phone cards a bit more vertical space so text doesn't feel cramped
                      final childAspectRatio = isLandscapeLocal
                          ? 0.78
                          : (isPhoneWidthLocal ? 0.68 : 0.75);

                      if (_initialLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_loadingSelected) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_loadError != null && _visibleItems.isEmpty) {
                        return Center(
                          child: Text(
                            'Failed to load menu items.\n$_loadError',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (_visibleItems.isEmpty) {
                        return const Center(
                          child: Text(
                            'No items found.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _visibleItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final item = _visibleItems[index];
                          return MenuItemCard(
                            item: item,
                            onTap: () async {
                              FocusScope.of(context).unfocus();

                              final key = _itemKey(item);
                              final productId =
                                  _menuDataStore.productIdByKey[key];

                              if (productId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not find product id for this item.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductVariationsPage(
                                    item: item,
                                    productId: productId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
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
