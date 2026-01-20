// Cheffery - menu_management_data_source.dart
//
// Data source for managing menu items (CRUD operations)
// Handles database operations for creating, updating, and deleting menu products

import 'package:supabase_flutter/supabase_flutter.dart';

class MenuManagementDataSource {
  MenuManagementDataSource(this.supabase);

  final SupabaseClient supabase;

  // =========================================================
  // Fetch store and menu information
  // =========================================================
  Future<Map<String, dynamic>?> getStoreAndMenu() async {
    final authUserId = supabase.auth.currentUser?.id;
    if (authUserId == null) return null;

    final storeRow = await supabase
        .from('stores')
        .select('id')
        .eq('owner_user_id', authUserId)
        .maybeSingle();

    final storeId = storeRow?['id'] as String?;
    if (storeId == null) return null;

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
    if (menuId == null) return null;

    return {'storeId': storeId, 'menuId': menuId};
  }

  // =========================================================
  // Fetch all categories
  // =========================================================
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final rows = await supabase
        .from('product_category')
        .select('id,category_name')
        .order('category_name', ascending: true);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // =========================================================
  // Fetch categories for current menu
  // =========================================================
  Future<List<Map<String, dynamic>>> fetchMenuCategories() async {
    final menuInfo = await getStoreAndMenu();
    if (menuInfo == null) return [];

    final menuId = menuInfo['menuId'] as int;

    final junctionRows = await supabase
        .from('store_menu_categories_junction')
        .select('id,id_product_category')
        .eq('menu_id_store_menu', menuId);

    final categoryIds = (junctionRows as List)
        .map((r) => r['id_product_category'] as int?)
        .whereType<int>()
        .toSet()
        .toList();

    if (categoryIds.isEmpty) return [];

    final catRows = await supabase
        .from('product_category')
        .select('id,category_name')
        .inFilter('id', categoryIds)
        .order('category_name', ascending: true);

    return (catRows as List).cast<Map<String, dynamic>>();
  }

  // =========================================================
  // Fetch all products grouped by category
  // =========================================================
  Future<Map<String, List<Map<String, dynamic>>>>
      fetchProductsByCategory() async {
    final menuInfo = await getStoreAndMenu();
    if (menuInfo == null) return {};

    final menuId = menuInfo['menuId'] as int;

    final junctionRows = await supabase
        .from('store_menu_categories_junction')
        .select('id,id_product_category')
        .eq('menu_id_store_menu', menuId);

    final junctionMap = <int, int>{};
    final categoryIds = <int>{};

    for (final row in junctionRows as List) {
      final junctionId = row['id'] as int;
      final categoryId = row['id_product_category'] as int;
      junctionMap[junctionId] = categoryId;
      categoryIds.add(categoryId);
    }

    if (categoryIds.isEmpty) return {};

    final categoryRows = await supabase
        .from('product_category')
        .select('id,category_name')
        .inFilter('id', categoryIds.toList());

    final categoryNames = <int, String>{};
    for (final row in categoryRows as List) {
      categoryNames[row['id'] as int] = row['category_name'] as String;
    }

    final productRows = await supabase
        .from('store_menu_products')
        .select(
          'product_id,name,subtitle,description,base_price,calories,protein,carbs,fat,image_uri,highlighted_feature,id_store_menu_categories_junction',
        )
        .inFilter('id_store_menu_categories_junction', junctionMap.keys.toList())
        .order('name', ascending: true);

    final result = <String, List<Map<String, dynamic>>>{};

    for (final product in productRows as List) {
      final junctionId =
          product['id_store_menu_categories_junction'] as int;
      final categoryId = junctionMap[junctionId];
      final categoryName = categoryNames[categoryId] ?? 'Unknown';

      if (!result.containsKey(categoryName)) {
        result[categoryName] = [];
      }

      result[categoryName]!.add({
        'product_id': product['product_id'],
        'name': product['name'],
        'subtitle': product['subtitle'],
        'description': product['description'],
        'base_price': product['base_price'],
        'calories': product['calories'],
        'protein': product['protein'],
        'carbs': product['carbs'],
        'fat': product['fat'],
        'image_uri': product['image_uri'],
        'highlighted_feature': product['highlighted_feature'],
        'category_id': categoryId,
        'junction_id': junctionId,
      });
    }

    return result;
  }

  // =========================================================
  // Get or create junction entry for menu + category
  // =========================================================
  Future<int?> getOrCreateJunction(int menuId, int categoryId) async {
    final existing = await supabase
        .from('store_menu_categories_junction')
        .select('id')
        .eq('menu_id_store_menu', menuId)
        .eq('id_product_category', categoryId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    final inserted = await supabase
        .from('store_menu_categories_junction')
        .insert({
          'menu_id_store_menu': menuId,
          'id_product_category': categoryId,
        })
        .select('id')
        .single();

    return inserted['id'] as int;
  }

  // =========================================================
  // Create new product
  // =========================================================
  Future<void> createProduct({
    required int categoryId,
    required String name,
    required String subtitle,
    required String description,
    required double basePrice,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    String? imageUri,
    String? highlightedFeature,
  }) async {
    final menuInfo = await getStoreAndMenu();
    if (menuInfo == null) throw Exception('No store or menu found');

    final menuId = menuInfo['menuId'] as int;

    final junctionId = await getOrCreateJunction(menuId, categoryId);
    if (junctionId == null) throw Exception('Failed to create junction');

    await supabase.from('store_menu_products').insert({
      'name': name,
      'subtitle': subtitle,
      'description': description,
      'base_price': basePrice,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'image_uri': imageUri,
      'highlighted_feature': highlightedFeature,
      'id_store_menu_categories_junction': junctionId,
    });
  }

  // =========================================================
  // Update existing product
  // =========================================================
  Future<void> updateProduct({
    required int productId,
    required int categoryId,
    required String name,
    required String subtitle,
    required String description,
    required double basePrice,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    String? imageUri,
    String? highlightedFeature,
  }) async {
    final menuInfo = await getStoreAndMenu();
    if (menuInfo == null) throw Exception('No store or menu found');

    final menuId = menuInfo['menuId'] as int;

    final junctionId = await getOrCreateJunction(menuId, categoryId);
    if (junctionId == null) throw Exception('Failed to get/create junction');

    await supabase
        .from('store_menu_products')
        .update({
          'name': name,
          'subtitle': subtitle,
          'description': description,
          'base_price': basePrice,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'image_uri': imageUri,
          'highlighted_feature': highlightedFeature,
          'id_store_menu_categories_junction': junctionId,
        })
        .eq('product_id', productId);
  }

  // =========================================================
  // Delete product
  // =========================================================
  Future<void> deleteProduct(int productId) async {
    await supabase
        .from('store_menu_products')
        .delete()
        .eq('product_id', productId);
  }

  // =========================================================
  // Create new category
  // =========================================================
  Future<int> createCategory(String categoryName) async {
    final result = await supabase
        .from('product_category')
        .insert({'category_name': categoryName})
        .select('id')
        .single();

    return result['id'] as int;
  }
}
