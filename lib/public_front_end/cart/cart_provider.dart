// cheffery - cart_providers.dart
//
// This is the provider for all things cart and checkout related

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/order_flow_providers.dart'
    as flow;

// =========================================================
// View Models
// =========================================================

class CartVariationVM {
  CartVariationVM({
    required this.id,
    required this.cartItemId,
    required this.variationId,
    required this.quantity,
    required this.variationName,
    required this.priceAdjustment,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int id;
  final int cartItemId;
  final int variationId;
  final int quantity;

  final String variationName;
  final double priceAdjustment;

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  factory CartVariationVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return CartVariationVM(
      id: (r['id'] as num).toInt(),
      cartItemId: (r['cart_item_id'] as num).toInt(),
      variationId: (r['variation_id'] as num).toInt(),
      quantity: (r['quantity'] as num).toInt(),
      variationName: (r['variation_name'] ?? '').toString(),
      priceAdjustment: _d(r['price_adjustment']),
      calories: _i(r['calories']),
      protein: _i(r['protein']),
      carbs: _i(r['carbs']),
      fat: _i(r['fat']),
    );
  }
}

/// Full VM for Cart UI: base snapshot + macros + variations + line totals
class CartItemVM {
  CartItemVM({
    required this.cartItemId,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.productDescription,
    required this.basePrice,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.instructions,
    required this.lineTotal,
    required this.variations,
  });

  final int cartItemId;
  final int productId;
  final int quantity;

  final String productName;
  final String? productDescription;

  // base snapshot (per 1 item)
  final double basePrice;
  final int baseCalories;
  final int baseProtein;
  final int baseCarbs;
  final int baseFat;

  final String? instructions;

  // stored subtotal for the cart line (quantity included)
  final double lineTotal;

  final List<CartVariationVM> variations;

  // ---------- Breakdown helpers ----------
  double get baseSubtotal => basePrice * quantity;

  /// Add-ons cost for ONE configured item (variation quantities are per item)
  double get addonsPerItem => variations.fold<double>(
    0,
    (s, v) => s + (v.priceAdjustment * v.quantity),
  );

  /// Add-ons cost for the WHOLE cart line
  double get addonsSubtotal => addonsPerItem * quantity;

  /// What the line total SHOULD be if you compute it locally
  double get computedLineTotal => baseSubtotal + addonsSubtotal;

  // ---------- Macros per configured item ----------
  int get addonsCaloriesPerItem =>
      variations.fold<int>(0, (s, v) => s + (v.calories * v.quantity));
  int get addonsProteinPerItem =>
      variations.fold<int>(0, (s, v) => s + (v.protein * v.quantity));
  int get addonsCarbsPerItem =>
      variations.fold<int>(0, (s, v) => s + (v.carbs * v.quantity));
  int get addonsFatPerItem =>
      variations.fold<int>(0, (s, v) => s + (v.fat * v.quantity));

  int get finalCaloriesPerItem => baseCalories + addonsCaloriesPerItem;
  int get finalProteinPerItem => baseProtein + addonsProteinPerItem;
  int get finalCarbsPerItem => baseCarbs + addonsCarbsPerItem;
  int get finalFatPerItem => baseFat + addonsFatPerItem;

  // ---------- Macros for the whole line (quantity included) ----------
  int get finalCaloriesLine => finalCaloriesPerItem * quantity;
  int get finalProteinLine => finalProteinPerItem * quantity;
  int get finalCarbsLine => finalCarbsPerItem * quantity;
  int get finalFatLine => finalFatPerItem * quantity;

  factory CartItemVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return CartItemVM(
      cartItemId: (r['cart_item_id'] as num).toInt(),
      productId: (r['product_id'] as num).toInt(),
      quantity: (r['quantity'] as num).toInt(),
      productName: (r['product_name'] ?? '').toString(),
      productDescription: (r['product_description'] as String?)?.trim(),
      basePrice: _d(r['base_price']),
      baseCalories: _i(r['calories']),
      baseProtein: _i(r['protein']),
      baseCarbs: _i(r['carbs']),
      baseFat: _i(r['fat']),
      instructions: (r['instructions'] as String?)?.trim(),
      lineTotal: _d(r['line_total']),
      variations: const <CartVariationVM>[],
    );
  }

  CartItemVM copyWith({List<CartVariationVM>? variations}) {
    return CartItemVM(
      cartItemId: cartItemId,
      productId: productId,
      quantity: quantity,
      productName: productName,
      productDescription: productDescription,
      basePrice: basePrice,
      baseCalories: baseCalories,
      baseProtein: baseProtein,
      baseCarbs: baseCarbs,
      baseFat: baseFat,
      instructions: instructions,
      lineTotal: lineTotal,
      variations: variations ?? this.variations,
    );
  }
}

// =========================================================
// Cart providers
// =========================================================

/// Loads cart items (full detail) + all variations for each line.
final cartItemsProvider = FutureProvider<List<CartItemVM>>((ref) async {
  final supabase = ref.read(supabaseProvider);

  // use global provider
  final orderId = await ref.watch(flow.currentOrderIdProvider.future);
  if (orderId == null) return const <CartItemVM>[];

  // 1) Load cart lines (base snapshot)
  final cartRows = await supabase
      .from('user_cart')
      .select(
        'cart_item_id,product_id,quantity,product_name,product_description,base_price,calories,protein,carbs,fat,instructions,line_total',
      )
      .eq('order_id', orderId)
      .order('cart_item_id', ascending: true);

  final cartList = (cartRows as List).cast<Map<String, dynamic>>();
  final baseItems = cartList.map(CartItemVM.fromRow).toList();
  if (baseItems.isEmpty) return baseItems;

  // 2) Load variations for all cart_item_ids
  final cartItemIds = baseItems.map((e) => e.cartItemId).toList();

  final varRows = await supabase
      .from('user_cart_variations')
      .select(
        'id,cart_item_id,variation_id,quantity,variation_name,price_adjustment,calories,protein,carbs,fat',
      )
      .inFilter('cart_item_id', cartItemIds)
      .order('id', ascending: true);

  final varList = (varRows as List).cast<Map<String, dynamic>>();

  final Map<int, List<CartVariationVM>> byCartItemId = {};
  for (final r in varList) {
    final cid = (r['cart_item_id'] as num).toInt();
    byCartItemId.putIfAbsent(cid, () => []).add(CartVariationVM.fromRow(r));
  }

  return baseItems
      .map(
        (it) => it.copyWith(
          variations: byCartItemId[it.cartItemId] ?? const <CartVariationVM>[],
        ),
      )
      .toList();
});

/// Total # of items in the cart (sum of quantities)
final cartCountProvider = Provider<int>((ref) {
  final asyncItems = ref.watch(cartItemsProvider);
  return asyncItems.maybeWhen(
    data: (items) => items.fold<int>(0, (sum, it) => sum + it.quantity),
    orElse: () => 0,
  );
});

/// Clears cart for a SPECIFIC orderId (best for Payment flow)
final clearCartByOrderIdProvider =
    Provider<Future<void> Function({required int orderId})>((ref) {
      return ({required int orderId}) async {
        final supabase = ref.read(supabaseProvider);

        final idsRows = await supabase
            .from('user_cart')
            .select('cart_item_id')
            .eq('order_id', orderId);

        final idsList = (idsRows as List).cast<Map<String, dynamic>>();
        final cartItemIds = idsList
            .map((r) => (r['cart_item_id'] as num).toInt())
            .toList();

        if (cartItemIds.isNotEmpty) {
          await supabase
              .from('user_cart_variations')
              .delete()
              .inFilter('cart_item_id', cartItemIds);
        }

        await supabase.from('user_cart').delete().eq('order_id', orderId);

        ref.invalidate(cartItemsProvider);
        ref.invalidate(cartCountProvider);
      };
    });

/// Clears the cart for the CURRENT order (store-scoped).
final clearCartProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final orderId = await ref.read(flow.currentOrderIdProvider.future);
    if (orderId == null) return;

    await ref.read(clearCartByOrderIdProvider)(orderId: orderId);
  };
});

// =========================================================
// Add to cart (full snapshot + variations)
// =========================================================

bool _sameVariationSet(
  List<Map<String, dynamic>> existing,
  List<Map<String, dynamic>> incoming,
) {
  // Compare by variation_id -> "qty|price"
  Map<int, String> sig(List<Map<String, dynamic>> rows) {
    final m = <int, String>{};
    for (final r in rows) {
      if (r['variation_id'] == null) continue;
      final id = (r['variation_id'] as num).toInt();
      final qty = ((r['quantity'] as num?) ?? 0).toInt();
      final price = (r['price_adjustment'] is num)
          ? (r['price_adjustment'] as num).toDouble()
          : 0.0;
      m[id] = '$qty|$price';
    }
    return m;
  }

  final a = sig(existing);
  final b = sig(incoming);

  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

/// Inserts a cart line item (one configured product).
/// Stores full product snapshot + inserts child variation rows.
final addToCartProvider =
    Provider<
      Future<void> Function({
        required int productId,
        required int quantity,
        required String productName,
        required String? productDescription,
        required double basePrice,
        required int calories,
        required int protein,
        required int carbs,
        required int fat,
        required double perItemFinalPrice, // price for ONE configured item
        String? instructions,
        required List<Map<String, dynamic>> selectedVariations,
        bool mergeIfSameConfig,
      })
    >((ref) {
      return ({
        required int productId,
        required int quantity,
        required String productName,
        required String? productDescription,
        required double basePrice,
        required int calories,
        required int protein,
        required int carbs,
        required int fat,
        required double perItemFinalPrice,
        String? instructions,
        required List<Map<String, dynamic>> selectedVariations,
        bool mergeIfSameConfig = true,
      }) async {
        final supabase = ref.read(supabaseProvider);

        final orderId = await ref.read(flow.currentOrderIdProvider.future);
        if (orderId == null) {
          throw Exception('No active cart order (missing user/store).');
        }

        // guard NOT NULL fields
        if (basePrice.isNaN) throw Exception('Invalid base_price (NaN).');
        if (perItemFinalPrice.isNaN) {
          throw Exception('Invalid perItemFinalPrice (NaN).');
        }

        final incomingInstructions = (instructions ?? '').trim();

        // ---------- MERGE (same product + same config) ----------
        if (mergeIfSameConfig) {
          final existingRows = await supabase
              .from('user_cart')
              .select('cart_item_id,quantity,instructions')
              .eq('order_id', orderId)
              .eq('product_id', productId);

          final existingList = (existingRows as List)
              .cast<Map<String, dynamic>>();

          for (final ex in existingList) {
            final cartItemId = (ex['cart_item_id'] as num).toInt();
            final existingInstructions =
                (ex['instructions'] as String?)?.trim() ?? '';

            if (existingInstructions != incomingInstructions) continue;

            final exVarRows = await supabase
                .from('user_cart_variations')
                .select('variation_id,quantity,price_adjustment')
                .eq('cart_item_id', cartItemId);

            final exVars = (exVarRows as List).cast<Map<String, dynamic>>();

            if (!_sameVariationSet(exVars, selectedVariations)) continue;

            final oldQty = (ex['quantity'] as num).toInt();
            final newQty = oldQty + quantity;

            await supabase
                .from('user_cart')
                .update({
                  'quantity': newQty,
                  'line_total': perItemFinalPrice * newQty,
                })
                .eq('cart_item_id', cartItemId);

            ref.invalidate(cartItemsProvider);
            ref.invalidate(cartCountProvider);
            return;
          }
        }

        // ---------- INSERT new cart line ----------
        final inserted = await supabase
            .from('user_cart')
            .insert({
              'order_id': orderId,
              'product_id': productId,
              'quantity': quantity,
              'product_name': productName,
              'product_description': productDescription,
              'base_price': basePrice,
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
              'instructions': incomingInstructions.isEmpty
                  ? null
                  : incomingInstructions,
              'line_total': perItemFinalPrice * quantity,
            })
            .select('cart_item_id')
            .single();

        final cartItemId = (inserted['cart_item_id'] as num).toInt();

        // ---------- INSERT variations snapshot ----------
        if (selectedVariations.isNotEmpty) {
          final payload = selectedVariations.map((v) {
            return {
              'cart_item_id': cartItemId,
              'variation_id': v['variation_id'],
              'quantity': v['quantity'] ?? 1,
              'variation_name': v['variation_name'] ?? '',
              'price_adjustment': v['price_adjustment'] ?? 0,
              'calories': v['calories'] ?? 0,
              'protein': v['protein'] ?? 0,
              'carbs': v['carbs'] ?? 0,
              'fat': v['fat'] ?? 0,
            };
          }).toList();

          await supabase.from('user_cart_variations').insert(payload);
        }

        ref.invalidate(cartItemsProvider);
        ref.invalidate(cartCountProvider);
      };
    });

// =========================================================
// Remove / Update qty
// =========================================================

/// Remove a single cart line (and its variations) by cart_item_id
final removeCartItemProvider = Provider<Future<void> Function(int cartItemId)>((
  ref,
) {
  return (cartItemId) async {
    final supabase = ref.read(supabaseProvider);

    await supabase
        .from('user_cart_variations')
        .delete()
        .eq('cart_item_id', cartItemId);

    await supabase.from('user_cart').delete().eq('cart_item_id', cartItemId);

    ref.invalidate(cartItemsProvider);
    ref.invalidate(cartCountProvider);
  };
});

/// Update quantity for a cart line (keeps variations config the same)
final updateCartItemQtyProvider =
    Provider<
      Future<void> Function({required int cartItemId, required int quantity})
    >((ref) {
      return ({required int cartItemId, required int quantity}) async {
        final supabase = ref.read(supabaseProvider);

        if (quantity <= 0) {
          await supabase
              .from('user_cart_variations')
              .delete()
              .eq('cart_item_id', cartItemId);

          await supabase
              .from('user_cart')
              .delete()
              .eq('cart_item_id', cartItemId);
        } else {
          // Recompute line_total using current per-item final price
          final row = await supabase
              .from('user_cart')
              .select('line_total,quantity')
              .eq('cart_item_id', cartItemId)
              .maybeSingle();

          if (row == null) return;

          final oldQty = (row['quantity'] as num).toInt();
          final oldLineTotal = (row['line_total'] is num)
              ? (row['line_total'] as num).toDouble()
              : 0.0;

          final perItemFinal = (oldQty > 0) ? (oldLineTotal / oldQty) : 0.0;

          await supabase
              .from('user_cart')
              .update({
                'quantity': quantity,
                'line_total': perItemFinal * quantity,
              })
              .eq('cart_item_id', cartItemId);
        }

        ref.invalidate(cartItemsProvider);
        ref.invalidate(cartCountProvider);
      };
    });
