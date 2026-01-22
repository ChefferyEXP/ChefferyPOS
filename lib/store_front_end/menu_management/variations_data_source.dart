// Cheffery - variations_data_source.dart
//
// Data source for managing product variations

import 'package:supabase_flutter/supabase_flutter.dart';

class VariationsDataSource {
  final SupabaseClient _supabase;

  VariationsDataSource(this._supabase);

  // ===========================
  // Variation Types (Groups)
  // ===========================

  /// Fetch all variation types
  Future<List<Map<String, dynamic>>> fetchAllVariationTypes() async {
    final response = await _supabase
        .from('product_variation_type')
        .select()
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new variation type
  Future<int> createVariationType({
    required String name,
    String? description,
    required int minSelection,
    required int maxSelection,
  }) async {
    final response = await _supabase
        .from('product_variation_type')
        .insert({
          'name': name,
          'description': description,
          'min_selection': minSelection,
          'max_selection': maxSelection,
        })
        .select('variation_type_id')
        .single();

    return response['variation_type_id'] as int;
  }

  /// Update a variation type
  Future<void> updateVariationType({
    required int variationTypeId,
    required String name,
    String? description,
    required int minSelection,
    required int maxSelection,
  }) async {
    await _supabase
        .from('product_variation_type')
        .update({
          'name': name,
          'description': description,
          'min_selection': minSelection,
          'max_selection': maxSelection,
        })
        .eq('variation_type_id', variationTypeId);
  }

  /// Delete a variation type
  Future<void> deleteVariationType(int variationTypeId) async {
    await _supabase
        .from('product_variation_type')
        .delete()
        .eq('variation_type_id', variationTypeId);
  }

  // ===========================
  // Variations
  // ===========================

  /// Fetch all variations for a specific variation type
  Future<List<Map<String, dynamic>>> fetchVariationsByType(
    int variationTypeId,
  ) async {
    final response = await _supabase
        .from('variations')
        .select()
        .eq('variation_type_id_product_variation_type', variationTypeId)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new variation
  Future<int> createVariation({
    required int variationTypeId,
    required String name,
    String? description,
    required double priceAdjustment,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
  }) async {
    final response = await _supabase
        .from('variations')
        .insert({
          'variation_type_id_product_variation_type': variationTypeId,
          'name': name,
          'description': description,
          'price_adjustment': priceAdjustment,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        })
        .select('variation_id')
        .single();

    return response['variation_id'] as int;
  }

  /// Update a variation
  Future<void> updateVariation({
    required int variationId,
    required String name,
    String? description,
    required double priceAdjustment,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
  }) async {
    await _supabase
        .from('variations')
        .update({
          'name': name,
          'description': description,
          'price_adjustment': priceAdjustment,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        })
        .eq('variation_id', variationId);
  }

  /// Delete a variation
  Future<void> deleteVariation(int variationId) async {
    await _supabase
        .from('variations')
        .delete()
        .eq('variation_id', variationId);
  }

  // ===========================
  // Product Variation Groups Junction
  // ===========================

  /// Fetch all variation groups assigned to a product with their variations
  Future<List<Map<String, dynamic>>> fetchProductVariationGroups(
    int productId,
  ) async {
    // First, get all variation type IDs assigned to this product
    final junctionResponse = await _supabase
        .from('menu_item_variation_groups_junction')
        .select('variation_type_id_product_variation_type')
        .eq('product_id_store_menu_products', productId);

    if (junctionResponse.isEmpty) {
      return [];
    }

    final variationTypeIds = (junctionResponse as List)
        .map((e) => e['variation_type_id_product_variation_type'] as int)
        .toList();

    // Fetch variation types
    final typesResponse = await _supabase
        .from('product_variation_type')
        .select()
        .inFilter('variation_type_id', variationTypeIds)
        .order('name');

    final List<Map<String, dynamic>> groups = [];

    for (final type in typesResponse) {
      final variationTypeId = type['variation_type_id'] as int;

      // Fetch allowed variations for this product and variation type
      final allowedVariationsResponse = await _supabase
          .from('product_allowed_variations')
          .select('''
            variation_id,
            is_default,
            default_quantity,
            sort_order,
            variations!inner(
              variation_id,
              name,
              description,
              price_adjustment,
              calories,
              protein,
              carbs,
              fat
            )
          ''')
          .eq('product_id', productId)
          .order('sort_order');

      // Filter variations that belong to this variation type
      final allVariations = await _supabase
          .from('variations')
          .select()
          .eq('variation_type_id_product_variation_type', variationTypeId);

      final variationIdsInType =
          allVariations.map((v) => v['variation_id'] as int).toSet();

      final filteredVariations = (allowedVariationsResponse as List)
          .where((v) => variationIdsInType.contains(v['variation_id']))
          .map((v) {
        final variation = v['variations'];
        return {
          'variation_id': v['variation_id'],
          'name': variation['name'],
          'description': variation['description'],
          'price_adjustment': variation['price_adjustment'],
          'calories': variation['calories'],
          'protein': variation['protein'],
          'carbs': variation['carbs'],
          'fat': variation['fat'],
          'is_default': v['is_default'],
          'default_quantity': v['default_quantity'],
          'sort_order': v['sort_order'],
        };
      }).toList();

      groups.add({
        'variation_type_id': variationTypeId,
        'name': type['name'],
        'description': type['description'],
        'min_selection': type['min_selection'],
        'max_selection': type['max_selection'],
        'variations': filteredVariations,
      });
    }

    return groups;
  }

  /// Add a variation group to a product
  /// This will automatically add ALL variations from that group to the product
  Future<void> addVariationGroupToProduct({
    required int productId,
    required int variationTypeId,
  }) async {
    // First, add the junction entry
    await _supabase
        .from('menu_item_variation_groups_junction')
        .insert({
          'product_id_store_menu_products': productId,
          'variation_type_id_product_variation_type': variationTypeId,
        });

    // Then, fetch all variations for this variation type
    final variations = await _supabase
        .from('variations')
        .select('variation_id')
        .eq('variation_type_id_product_variation_type', variationTypeId);

    if (variations.isEmpty) return;

    // Add all variations from this group to the product
    final variationInserts = <Map<String, dynamic>>[];
    int sortOrder = 0;

    for (final variation in variations) {
      variationInserts.add({
        'product_id': productId,
        'variation_id': variation['variation_id'],
        'is_default': false,
        'default_quantity': 1,
        'sort_order': sortOrder++,
      });
    }

    if (variationInserts.isNotEmpty) {
      await _supabase
          .from('product_allowed_variations')
          .insert(variationInserts);
    }
  }

  /// Remove a variation group from a product
  Future<void> removeVariationGroupFromProduct({
    required int productId,
    required int variationTypeId,
  }) async {
    // First, remove all allowed variations for this product and variation type
    final variationsInType = await _supabase
        .from('variations')
        .select('variation_id')
        .eq('variation_type_id_product_variation_type', variationTypeId);

    final variationIds = (variationsInType as List)
        .map((v) => v['variation_id'] as int)
        .toList();

    if (variationIds.isNotEmpty) {
      await _supabase
          .from('product_allowed_variations')
          .delete()
          .eq('product_id', productId)
          .inFilter('variation_id', variationIds);
    }

    // Then remove the junction entry
    await _supabase
        .from('menu_item_variation_groups_junction')
        .delete()
        .eq('product_id_store_menu_products', productId)
        .eq('variation_type_id_product_variation_type', variationTypeId);
  }

  // ===========================
  // Product Allowed Variations
  // ===========================

  /// Add a variation to a product
  Future<void> addVariationToProduct({
    required int productId,
    required int variationId,
    bool isDefault = false,
    int defaultQuantity = 1,
    int sortOrder = 0,
  }) async {
    await _supabase
        .from('product_allowed_variations')
        .insert({
          'product_id': productId,
          'variation_id': variationId,
          'is_default': isDefault,
          'default_quantity': defaultQuantity,
          'sort_order': sortOrder,
        });
  }

  /// Update variation settings for a product
  Future<void> updateProductVariationSettings({
    required int productId,
    required int variationId,
    bool? isDefault,
    int? defaultQuantity,
    int? sortOrder,
  }) async {
    final Map<String, dynamic> updates = {};
    if (isDefault != null) updates['is_default'] = isDefault;
    if (defaultQuantity != null) updates['default_quantity'] = defaultQuantity;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    if (updates.isEmpty) return;

    await _supabase
        .from('product_allowed_variations')
        .update(updates)
        .eq('product_id', productId)
        .eq('variation_id', variationId);
  }

  /// Remove a variation from a product
  Future<void> removeVariationFromProduct({
    required int productId,
    required int variationId,
  }) async {
    await _supabase
        .from('product_allowed_variations')
        .delete()
        .eq('product_id', productId)
        .eq('variation_id', variationId);
  }

  /// Fetch available variation types that are NOT assigned to a product
  Future<List<Map<String, dynamic>>> fetchAvailableVariationTypes(
    int productId,
  ) async {
    // Get all variation types
    final allTypes = await fetchAllVariationTypes();

    // Get assigned variation type IDs
    final assignedResponse = await _supabase
        .from('menu_item_variation_groups_junction')
        .select('variation_type_id_product_variation_type')
        .eq('product_id_store_menu_products', productId);

    final assignedIds = (assignedResponse as List)
        .map((e) => e['variation_type_id_product_variation_type'] as int)
        .toSet();

    // Filter out assigned types
    return allTypes
        .where((type) => !assignedIds.contains(type['variation_type_id']))
        .toList();
  }

  /// Fetch variations for a variation type that are NOT assigned to a product
  Future<List<Map<String, dynamic>>> fetchAvailableVariations({
    required int productId,
    required int variationTypeId,
  }) async {
    // Get all variations for this type
    final allVariations = await fetchVariationsByType(variationTypeId);

    // Get assigned variation IDs
    final assignedResponse = await _supabase
        .from('product_allowed_variations')
        .select('variation_id')
        .eq('product_id', productId);

    final assignedIds = (assignedResponse as List)
        .map((e) => e['variation_id'] as int)
        .toSet();

    // Filter out assigned variations
    return allVariations
        .where((variation) => !assignedIds.contains(variation['variation_id']))
        .toList();
  }

  // ===========================
  // Cleanup Operations
  // ===========================

  /// Find all variations that are NOT assigned to any product
  Future<List<Map<String, dynamic>>> fetchUnusedVariations() async {
    // Get all variations
    final allVariations = await _supabase
        .from('variations')
        .select('''
          variation_id,
          name,
          variation_type_id_product_variation_type,
          product_variation_type!inner(name)
        ''')
        .order('name');

    // Get all variation IDs that are in use
    final usedVariations = await _supabase
        .from('product_allowed_variations')
        .select('variation_id');

    final usedIds = (usedVariations as List)
        .map((e) => e['variation_id'] as int)
        .toSet();

    // Filter to only unused variations
    return (allVariations as List)
        .where((v) => !usedIds.contains(v['variation_id']))
        .map((v) => {
              'variation_id': v['variation_id'],
              'name': v['name'],
              'variation_type_id': v['variation_type_id_product_variation_type'],
              'type_name': v['product_variation_type']['name'],
            })
        .toList();
  }

  /// Delete all unused variations
  Future<int> deleteUnusedVariations() async {
    final unusedVariations = await fetchUnusedVariations();

    if (unusedVariations.isEmpty) return 0;

    final variationIds = unusedVariations
        .map((v) => v['variation_id'] as int)
        .toList();

    await _supabase
        .from('variations')
        .delete()
        .inFilter('variation_id', variationIds);

    return variationIds.length;
  }

  /// Find all variation types that are NOT assigned to any product
  Future<List<dynamic>> fetchUnusedVariationTypes() async {
    // Get all variation types
    final allTypes = await _supabase
        .from('product_variation_type')
        .select()
        .order('name');

    // Get all variation type IDs that are in use
    final usedTypes = await _supabase
        .from('menu_item_variation_groups_junction')
        .select('variation_type_id_product_variation_type');

    final usedIds = (usedTypes as List)
        .map((e) => e['variation_type_id_product_variation_type'] as int)
        .toSet();

    // Filter to only unused types
    return (allTypes as List)
        .where((type) => !usedIds.contains(type['variation_type_id']))
        .toList();
  }

  /// Delete all unused variation types (and their associated variations)
  Future<int> deleteUnusedVariationTypes() async {
    final unusedTypes = await fetchUnusedVariationTypes();

    if (unusedTypes.isEmpty) return 0;

    final typeIds = unusedTypes
        .map((t) => t['variation_type_id'] as int)
        .toList();

    // First, delete all variations belonging to these types
    await _supabase
        .from('variations')
        .delete()
        .inFilter('variation_type_id_product_variation_type', typeIds);

    // Then delete the variation types themselves
    await _supabase
        .from('product_variation_type')
        .delete()
        .inFilter('variation_type_id', typeIds);

    return typeIds.length;
  }
}
