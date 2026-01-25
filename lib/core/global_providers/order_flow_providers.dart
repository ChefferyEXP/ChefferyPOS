import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_store_provider.dart';

// ====== Match your enum values here ======
const String kStatusCart = 'cart';
const String kStatusCurrent = 'current';
const String kStatusPlaced = 'placed';
const String kStatusCompleted = 'completed';
const String kStatusCancelled = 'cancelled';

// =====================================================
// View Models
// =====================================================

class CurrentOrderVM {
  CurrentOrderVM({
    required this.orderId,
    required this.userId,
    required this.storeId,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    required this.placedAt,
  });

  final int orderId;
  final int userId;
  final String storeId;
  final String status;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? placedAt;

  factory CurrentOrderVM.fromRow(Map<String, dynamic> r) {
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    DateTime _dt(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.tryParse(v.toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return CurrentOrderVM(
      orderId: (r['order_id'] as num).toInt(),
      userId: (r['user_id'] as num).toInt(),
      storeId: (r['store_id'] ?? '').toString(),
      status: (r['status'] ?? '').toString(),
      subtotal: _d(r['subtotal']),
      tax: _d(r['tax']),
      total: _d(r['total']),
      createdAt: _dt(r['created_at']),
      updatedAt: _dt(r['updated_at']),
      placedAt: r['placed_at'] == null ? null : _dt(r['placed_at']),
    );
  }
}

class OrderLineVM {
  OrderLineVM({
    required this.cartItemId,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.productDescription,
    required this.basePrice,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.instructions,
    required this.lineTotal,
    required this.variations,
  });

  final int cartItemId;
  final int productId;
  final int quantity;
  final String productName;
  final String? productDescription;
  final double basePrice;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String? instructions;
  final double lineTotal;
  final List<OrderLineVariationVM> variations;

  factory OrderLineVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return OrderLineVM(
      cartItemId: (r['cart_item_id'] as num).toInt(),
      productId: (r['product_id'] as num).toInt(),
      quantity: (r['quantity'] as num).toInt(),
      productName: (r['product_name'] ?? '').toString(),
      productDescription: (r['product_description'] as String?)?.trim(),
      basePrice: _d(r['base_price']),
      calories: _i(r['calories']),
      protein: _i(r['protein']),
      carbs: _i(r['carbs']),
      fat: _i(r['fat']),
      instructions: (r['instructions'] as String?)?.trim(),
      lineTotal: _d(r['line_total']),
      variations: const [],
    );
  }

  OrderLineVM copyWith({List<OrderLineVariationVM>? variations}) {
    return OrderLineVM(
      cartItemId: cartItemId,
      productId: productId,
      quantity: quantity,
      productName: productName,
      productDescription: productDescription,
      basePrice: basePrice,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      instructions: instructions,
      lineTotal: lineTotal,
      variations: variations ?? this.variations,
    );
  }
}

class OrderLineVariationVM {
  OrderLineVariationVM({
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

  factory OrderLineVariationVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return OrderLineVariationVM(
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

// =====================================================
// Current order helpers
// =====================================================

/// Finds or creates the current "cart" order for:
///   (active POS user, active store)
final currentOrderIdProvider = FutureProvider<int?>((ref) async {
  final supabase = ref.read(supabaseProvider);

  // watch so provider re-evaluates when these change
  final posUserId = ref.watch(activePosUserIdProvider);
  final storeId = ref.watch(activeStoreIdProvider);

  if (posUserId == null) return null;
  if (storeId == null || storeId.trim().isEmpty) return null;

  final existing = await supabase
      .from('user_current_order')
      .select('order_id')
      .eq('user_id', posUserId)
      .eq('store_id', storeId)
      .eq('status', kStatusCart)
      .maybeSingle();

  if (existing != null) return (existing['order_id'] as num).toInt();

  final created = await supabase
      .from('user_current_order')
      .insert({
        'user_id': posUserId,
        'store_id': storeId,
        'status': kStatusCart,
      })
      .select('order_id')
      .single();

  return (created['order_id'] as num).toInt();
});

/// Loads the order header by orderId
final orderByIdProvider = FutureProvider.family<CurrentOrderVM, int>((
  ref,
  orderId,
) async {
  final supabase = ref.read(supabaseProvider);

  final row = await supabase
      .from('user_current_order')
      .select(
        'order_id,user_id,store_id,status,subtotal,tax,total,created_at,updated_at,placed_at',
      )
      .eq('order_id', orderId)
      .single();

  return CurrentOrderVM.fromRow((row as Map).cast<String, dynamic>());
});

/// Loads cart lines + variations for a given orderId (even after status changes)
final orderLinesByOrderIdProvider = FutureProvider.family<List<OrderLineVM>, int>((
  ref,
  orderId,
) async {
  final supabase = ref.read(supabaseProvider);

  final cartRows = await supabase
      .from('user_cart')
      .select(
        'cart_item_id,product_id,quantity,product_name,product_description,base_price,calories,protein,carbs,fat,instructions,line_total',
      )
      .eq('order_id', orderId)
      .order('cart_item_id', ascending: true);

  final baseItems = (cartRows as List)
      .cast<Map<String, dynamic>>()
      .map(OrderLineVM.fromRow)
      .toList();
  if (baseItems.isEmpty) return baseItems;

  final ids = baseItems.map((e) => e.cartItemId).toList();

  final varRows = await supabase
      .from('user_cart_variations')
      .select(
        'id,cart_item_id,variation_id,quantity,variation_name,price_adjustment,calories,protein,carbs,fat',
      )
      .inFilter('cart_item_id', ids)
      .order('id', ascending: true);

  final vlist = (varRows as List).cast<Map<String, dynamic>>();
  final byCid = <int, List<OrderLineVariationVM>>{};
  for (final r in vlist) {
    final cid = (r['cart_item_id'] as num).toInt();
    byCid.putIfAbsent(cid, () => []).add(OrderLineVariationVM.fromRow(r));
  }

  return baseItems
      .map((it) => it.copyWith(variations: byCid[it.cartItemId] ?? const []))
      .toList();
});

// =====================================================
// Actions
// =====================================================

/// Called from Payment Success:
/// - updates user_current_order totals
/// - sets status to PLACED (your enum)
/// - sets placed_at
final markOrderPlacedProvider =
    Provider<
      Future<int> Function({
        required int orderId,
        required double total,
        required double taxRate,
      })
    >((ref) {
      return ({
        required int orderId,
        required double total,
        required double taxRate,
      }) async {
        final supabase = ref.read(supabaseProvider);

        final nowIso = DateTime.now().toIso8601String();

        final subtotal = total / (1.0 + taxRate);
        final tax = total - subtotal;

        await supabase
            .from('user_current_order')
            .update({
              'status': kStatusPlaced, // must match your enum
              'subtotal': subtotal,
              'tax': tax,
              'total': total,
              'placed_at': nowIso,
              'updated_at': nowIso,
            })
            .eq('order_id', orderId);

        ref.invalidate(orderByIdProvider(orderId));
        ref.invalidate(orderLinesByOrderIdProvider(orderId));
        ref.invalidate(currentOrderIdProvider);

        return orderId;
      };
    });

/// Called from "Complete Order":
/// - builds a JSON snapshot (order header + lines + variations)
/// - inserts into user_order_history
/// - deletes cart rows (variations first)
/// - marks current order as COMPLETED
final completeOrderProvider =
    Provider<Future<void> Function({required int orderId})>((ref) {
      return ({required int orderId}) async {
        final supabase = ref.read(supabaseProvider);

        final order = await ref.read(orderByIdProvider(orderId).future);
        final lines = await ref.read(
          orderLinesByOrderIdProvider(orderId).future,
        );

        final snapshot = {
          'order': {
            'order_id': order.orderId,
            'user_id': order.userId,
            'store_id': order.storeId,
            'status': order.status,
            'subtotal': order.subtotal,
            'tax': order.tax,
            'total': order.total,
            'created_at': order.createdAt.toIso8601String(),
            'updated_at': order.updatedAt.toIso8601String(),
            'placed_at': order.placedAt?.toIso8601String(),
          },
          'lines': [
            for (final l in lines)
              {
                'cart_item_id': l.cartItemId,
                'product_id': l.productId,
                'quantity': l.quantity,
                'product_name': l.productName,
                'product_description': l.productDescription,
                'base_price': l.basePrice,
                'calories': l.calories,
                'protein': l.protein,
                'carbs': l.carbs,
                'fat': l.fat,
                'instructions': l.instructions,
                'line_total': l.lineTotal,
                'variations': [
                  for (final v in l.variations)
                    {
                      'variation_id': v.variationId,
                      'quantity': v.quantity,
                      'variation_name': v.variationName,
                      'price_adjustment': v.priceAdjustment,
                      'calories': v.calories,
                      'protein': v.protein,
                      'carbs': v.carbs,
                      'fat': v.fat,
                    },
                ],
              },
          ],
        };

        // Insert into history
        await supabase.from('user_order_history').insert({
          'user_id': order.userId,
          'store_id': order.storeId,
          'placed_at': (order.placedAt ?? DateTime.now()).toIso8601String(),
          'total': order.total,
          'order_snapshot': snapshot, // jsonb
        });

        // Clear cart rows for this order
        final ids = lines.map((e) => e.cartItemId).toList();
        if (ids.isNotEmpty) {
          await supabase
              .from('user_cart_variations')
              .delete()
              .inFilter('cart_item_id', ids);
        }
        await supabase.from('user_cart').delete().eq('order_id', orderId);

        // Mark order completed
        final nowIso = DateTime.now().toIso8601String();
        await supabase
            .from('user_current_order')
            .update({'status': kStatusCompleted, 'updated_at': nowIso})
            .eq('order_id', orderId);

        ref.invalidate(orderByIdProvider(orderId));
        ref.invalidate(orderLinesByOrderIdProvider(orderId));
        ref.invalidate(currentOrderIdProvider);
      };
    });
