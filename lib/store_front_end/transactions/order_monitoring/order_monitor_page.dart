// order_monitor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/order_flow_providers.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_store_provider.dart';

// order_monitor_page.dart
//
// Live store order monitor (Supabase realtime stream)
// - Newest orders at top (placed_at -> updated_at fallback)
// - Expands each order to show FULL order details (lines + variations)
// - "Complete" button per order
//
// Instant UI removal when completed (optimistic hide)
// Automatically re-shows if complete fails

// ==============================
// Theme constants (dark monitor)
// ==============================
const Color _bg = Color(0xFF1F2329);
const Color _appBar = Color(0xFF2A2D34);
const Color _card = Color(0xFF262A31);
const Color _border = Color(0xFF3A3F49);
const Color _muted = Color(0xFFB5BBC6);
const Color _accent = Color(0xFF00E676);

// ==============================
// View Models
// ==============================
class StoreOrderVM {
  StoreOrderVM({
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

  factory StoreOrderVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    DateTime _dt(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.tryParse(v.toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return StoreOrderVM(
      orderId: _i(r['order_id']),
      userId: _i(r['user_id']),
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

class MonitorLineVariationVM {
  MonitorLineVariationVM({
    required this.variationName,
    required this.quantity,
    required this.priceAdjustment,
  });

  final String variationName;
  final int quantity;
  final double priceAdjustment;

  factory MonitorLineVariationVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return MonitorLineVariationVM(
      variationName: (r['variation_name'] ?? '').toString(),
      quantity: _i(r['quantity']),
      priceAdjustment: _d(r['price_adjustment']),
    );
  }
}

class MonitorLineVM {
  MonitorLineVM({
    required this.cartItemId,
    required this.productName,
    required this.quantity,
    required this.instructions,
    required this.lineTotal,
    required this.variations,
  });

  final int cartItemId;
  final String productName;
  final int quantity;
  final String? instructions;
  final double lineTotal;
  final List<MonitorLineVariationVM> variations;

  factory MonitorLineVM.fromRow(Map<String, dynamic> r) {
    int _i(dynamic v) => (v is num) ? v.toInt() : 0;
    double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return MonitorLineVM(
      cartItemId: _i(r['cart_item_id']),
      productName: (r['product_name'] ?? '').toString(),
      quantity: _i(r['quantity']),
      instructions: (r['instructions'] as String?)?.trim(),
      lineTotal: _d(r['line_total']),
      variations: const [],
    );
  }

  MonitorLineVM copyWith({List<MonitorLineVariationVM>? variations}) {
    return MonitorLineVM(
      cartItemId: cartItemId,
      productName: productName,
      quantity: quantity,
      instructions: instructions,
      lineTotal: lineTotal,
      variations: variations ?? this.variations,
    );
  }
}

// ==============================
// Status filtering
// Show active orders on monitor:
// - placed (payment success)
// - current (optional)
// ==============================
bool _isMonitorStatus(String s) {
  final v = s.toLowerCase().trim();
  return v == 'placed' || v == 'current';
}

// ==============================
// Optimistic UI: hidden orders
// ==============================
final hiddenMonitorOrdersProvider = StateProvider.autoDispose<Set<int>>(
  (ref) => <int>{},
);

// ==============================
// LIVE stream provider (Supabase Realtime)
// ==============================
final storeOrdersMonitorProvider =
    StreamProvider.autoDispose<List<StoreOrderVM>>((ref) {
      final storeId = ref.watch(activeStoreIdProvider);

      if (storeId == null || storeId.trim().isEmpty) {
        return Stream.value(const <StoreOrderVM>[]);
      }

      final hidden = ref.watch(hiddenMonitorOrdersProvider);
      final supabase = ref.read(supabaseProvider);

      return supabase
          .from('user_current_order')
          .stream(primaryKey: const ['order_id'])
          .eq('store_id', storeId)
          .map((rows) {
            final list = rows
                .cast<Map<String, dynamic>>()
                .map(StoreOrderVM.fromRow)
                .where((o) => _isMonitorStatus(o.status))
                .where((o) => !hidden.contains(o.orderId)) // hide instantly
                .toList();

            // newest first (prefer placed_at, otherwise updated_at)
            list.sort((a, b) {
              final at = a.placedAt ?? a.updatedAt;
              final bt = b.placedAt ?? b.updatedAt;
              return bt.compareTo(at);
            });

            return list;
          });
    });

// ==============================
// Per-order LIVE details stream
// (lines + variations) so the card updates live too
// ==============================
final orderDetailsStreamProvider = StreamProvider.autoDispose
    .family<List<MonitorLineVM>, int>((ref, orderId) {
      final supabase = ref.read(supabaseProvider);

      // Stream cart lines for this order
      final linesStream = supabase
          .from('user_cart')
          .stream(primaryKey: const ['cart_item_id'])
          .eq('order_id', orderId)
          .order('cart_item_id');

      // Stream variations for lines in this order
      // For realtime simplicity, stream ALL variations and filter by current cart_item_ids.
      final varsStream = supabase
          .from('user_cart_variations')
          .stream(primaryKey: const ['id'])
          .order('id');

      // Combine both streams
      return Rx.combineLatest2<
        List<Map<String, dynamic>>,
        List<Map<String, dynamic>>,
        List<MonitorLineVM>
      >(
        linesStream.map((e) => e.cast<Map<String, dynamic>>()),
        varsStream.map((e) => e.cast<Map<String, dynamic>>()),
        (lineRows, varRows) {
          final baseLines = lineRows.map(MonitorLineVM.fromRow).toList();
          if (baseLines.isEmpty) return const <MonitorLineVM>[];

          final lineIds = baseLines.map((e) => e.cartItemId).toSet();

          final byCartItem = <int, List<MonitorLineVariationVM>>{};
          for (final r in varRows) {
            final cid = (r['cart_item_id'] is num)
                ? (r['cart_item_id'] as num).toInt()
                : -1;
            if (!lineIds.contains(cid)) continue;
            byCartItem
                .putIfAbsent(cid, () => [])
                .add(MonitorLineVariationVM.fromRow(r));
          }

          return baseLines
              .map(
                (l) => l.copyWith(
                  variations: byCartItem[l.cartItemId] ?? const [],
                ),
              )
              .toList();
        },
      );
    });

// CombineLatest helper without adding rxdart dependency.
// If have rxdart, can delete this and use Rx.combineLatest2.
class Rx {
  static Stream<R> combineLatest2<A, B, R>(
    Stream<A> a,
    Stream<B> b,
    R Function(A, B) combiner,
  ) {
    late StreamController<R> controller;
    controller = StreamController<R>(
      onListen: () {
        A? lastA;
        B? lastB;
        bool hasA = false;
        bool hasB = false;

        final subA = a.listen((va) {
          lastA = va;
          hasA = true;
          if (hasA && hasB) controller.add(combiner(lastA as A, lastB as B));
        }, onError: controller.addError);

        final subB = b.listen((vb) {
          lastB = vb;
          hasB = true;
          if (hasA && hasB) controller.add(combiner(lastA as A, lastB as B));
        }, onError: controller.addError);

        controller.onCancel = () async {
          await subA.cancel();
          await subB.cancel();
        };
      },
    );

    return controller.stream;
  }
}

// ==============================
// Page
// ==============================
class OrderMonitorPage extends ConsumerWidget {
  const OrderMonitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(activeStoreIdProvider);
    final ordersAsync = ref.watch(storeOrdersMonitorProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Order Monitor',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: _appBar,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // clear local hides and refresh stream mapping
              ref.invalidate(hiddenMonitorOrdersProvider);
              ref.invalidate(storeOrdersMonitorProvider);
            },
          ),
        ],
      ),
      body: storeId == null
          ? const _EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'No store found',
              subtitle: 'Log in as a store owner to view live orders.',
            )
          : ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent),
              ),
              error: (e, _) => _ErrorState(
                error: e.toString(),
                onRetry: () => ref.invalidate(storeOrdersMonitorProvider),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No active orders',
                    subtitle:
                        'Orders will appear automatically when payment is successful.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                );
              },
            ),
    );
  }
}

// ==============================
// Order card with full details + Complete button
// ==============================
class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final StoreOrderVM order;

  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '—';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeColor = order.status.toLowerCase() == 'placed'
        ? _accent
        : Colors.amber;

    final linesAsync = ref.watch(orderDetailsStreamProvider(order.orderId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // order #
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Center(
                    child: Text(
                      '#${order.orderId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: badgeColor.withOpacity(0.55),
                              ),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Customer #${order.userId}',
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _MiniMeta(
                            icon: Icons.access_time,
                            text: 'Placed: ${_timeLabel(order.placedAt)}',
                          ),
                          _MiniMeta(
                            icon: Icons.update,
                            text: 'Updated: ${_timeLabel(order.updatedAt)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(order.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 12),

            // Order totals strip
            Row(
              children: [
                Expanded(
                  child: _TotalChip(
                    label: 'Subtotal',
                    value: _money(order.subtotal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalChip(label: 'Tax', value: _money(order.tax)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalChip(label: 'Total', value: _money(order.total)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details (lines)
            linesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: _accent)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Failed to load order items.\n$e',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              data: (lines) {
                if (lines.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'No items found for this order.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final l in lines) ...[
                      _LineTile(line: l),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 6),

            // Complete button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // hide order item on complete instantly
                  ref
                      .read(hiddenMonitorOrdersProvider.notifier)
                      .update((s) => {...s, order.orderId});

                  try {
                    await ref.read(completeOrderProvider)(
                      orderId: order.orderId,
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order #${order.orderId} completed.'),
                      ),
                    );
                  } catch (e) {
                    // ❌ undo hide if failed
                    ref.read(hiddenMonitorOrdersProvider.notifier).update((s) {
                      final copy = {...s};
                      copy.remove(order.orderId);
                      return copy;
                    });

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to complete.\n$e')),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.black87),
                label: const Text(
                  'Complete Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final MonitorLineVM line;

  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'x${line.quantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _money(line.lineTotal),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (line.instructions != null && line.instructions!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Instructions: ${line.instructions}',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (line.variations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in line.variations)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20242B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      '${v.variationName}${v.quantity > 1 ? " x${v.quantity}" : ""}'
                      '${v.priceAdjustment != 0 ? " (+${_money(v.priceAdjustment)})" : ""}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// Reusable UI states
// ==============================
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.white24),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.white30),
            const SizedBox(height: 14),
            const Text(
              'Error loading orders',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.black87),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
