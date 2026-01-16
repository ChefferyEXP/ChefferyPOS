// Cheffery - menu_data_source.dart
//
// This is what fetches the main menu data. Including a product ID for each tile for use in variations and cart

import 'package:flutter/material.dart';

import 'package:v0_0_0_cheffery_pos/public_front_end/menu/menu_models.dart';

class MenuDataSource {
  MenuDataSource(this.supabase);

  final dynamic supabase;

  // ===============================
  // ProductId lookup - Used to pass to variations and cart
  // ===============================
  final Map<String, int> _productIdByKey = {};

  // Expose read-only getter
  Map<String, int> get productIdByKey => _productIdByKey;

  // Must match how MenuCardItem is constructed (name/subtitle/image_uri)
  String _itemKey({
    required String name,
    required String subtitle,
    required String? imageUri,
  }) {
    return '${name.trim()}||${subtitle.trim()}||${(imageUri ?? '').trim()}';
  }

  // =========================================================
  // Categories
  // =========================================================
  Future<List<MenuCategoryTab>> fetchCategoriesForCurrentStoreMenu() async {
    final authUserId = supabase.auth.currentUser?.id;
    if (authUserId == null) return const [];

    final storeRow = await supabase
        .from('stores')
        .select('id')
        .eq('owner_user_id', authUserId)
        .maybeSingle();

    final storeId = storeRow?['id'] as String?;
    if (storeId == null) return const [];

    final mainMenuRow = await supabase
        .from('store_menu')
        .select('menu_id')
        .eq('store_id', storeId)
        .eq('name', 'Main Menu')
        .maybeSingle();

    final anyMenuRow = await supabase
        .from('store_menu')
        .select('menu_id')
        .eq('store_id', storeId)
        .order('menu_id', ascending: true)
        .maybeSingle();

    final menuId = (mainMenuRow?['menu_id'] ?? anyMenuRow?['menu_id']) as int?;
    if (menuId == null) return const [];

    final junctionRows = await supabase
        .from('store_menu_categories_junction')
        .select('id_product_category')
        .eq('menu_id_store_menu', menuId);

    final categoryIds = (junctionRows as List)
        .map((r) => r['id_product_category'] as int?)
        .whereType<int>()
        .toSet()
        .toList();

    if (categoryIds.isEmpty) return const [];

    final catRows = await supabase
        .from('product_category')
        .select('id,category_name')
        .inFilter('id', categoryIds)
        .order('category_name', ascending: true);

    final tabs = (catRows as List)
        .map((r) {
          return MenuCategoryTab(
            storeId: storeId,
            menuId: menuId,
            categoryId: r['id'] as int,
            label: (r['category_name'] ?? '').toString(),
          );
        })
        .where((t) => t.label.trim().isNotEmpty)
        .toList();

    return tabs;
  }

  // =========================================================
  // Items for a category
  // =========================================================
  Future<List<MenuCardItem>> fetchMenuItemsForCategory({
    required BuildContext context,
    required MenuCategoryTab tab,
  }) async {
    final junctionRows = await supabase
        .from('store_menu_categories_junction')
        .select('id')
        .eq('menu_id_store_menu', tab.menuId)
        .eq('id_product_category', tab.categoryId);

    final junctionIds = (junctionRows as List)
        .map((r) => r['id'] as int?)
        .whereType<int>()
        .toList();

    if (junctionIds.isEmpty) return const [];

    final productRows = await supabase
        .from('store_menu_products')
        .select(
          'product_id,name,subtitle,calories,highlighted_feature,image_uri,protein',
        )
        .inFilter('id_store_menu_categories_junction', junctionIds)
        .order('product_id', ascending: true);

    final baseItems = (productRows as List).map((r) {
      final productId = r['product_id'] as int;

      final name = (r['name'] ?? '').toString();
      final subtitleRaw = (r['subtitle'] ?? '').toString();
      final subtitle = subtitleRaw.isEmpty ? '—' : subtitleRaw;

      final caloriesVal = r['calories'];
      final highlighted =
          (r['highlighted_feature'] as String?) ??
          fallbackHighlightedFeature(r);

      final imageUri = (r['image_uri'] as String?)?.trim();
      final normalizedImageUri = (imageUri == null || imageUri.isEmpty)
          ? null
          : imageUri.replaceFirst(RegExp(r'^menu-images/'), '');

      // Store product_id lookup using the EXACT values that go into MenuCardItem
      final key = _itemKey(
        name: name,
        subtitle: subtitle,
        imageUri: normalizedImageUri,
      );
      _productIdByKey[key] = productId;

      return MenuCardItem(
        name: name,
        subtitle: subtitle,
        calories: caloriesVal == null ? '' : '${caloriesVal} cal',
        highlighted_feature: highlighted,
        image_uri: normalizedImageUri,
        signedImageUrl: null,
        badgeText: null,
      );
    }).toList();

    if (baseItems.isEmpty) return baseItems;

    // 1) Sign URLs
    final signedItems = await Future.wait(
      baseItems.map((item) async {
        final path = item.image_uri?.trim();
        if (path == null || path.isEmpty) return item;

        try {
          final signedUrl = await supabase.storage
              .from('menu-images')
              .createSignedUrl(path, 3600);
          return item.copyWith(signedImageUrl: signedUrl);
        } catch (_) {
          return item;
        }
      }),
    );

    // 2) Precache ALL signed images BEFORE returning
    final urlsToCache = signedItems
        .map((i) => i.signedImageUrl)
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final url in urlsToCache) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {}
    }

    return signedItems;
  }

  // =========================================================
  // Helpers
  // =========================================================
  String fallbackHighlightedFeature(Map row) {
    final protein = row['protein'];
    if (protein == null) return '';
    return '${protein}g protein';
  }
}
