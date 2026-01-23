// Cheffery - checkout_page.dart
//
// Checkout page to display all items added by the user, show details of cost, and proceed to payment, UI needs some work

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/checkout/payment_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  // Prevent: "A dismissed Dismissible widget is still part of the tree"
  final Set<int> _pendingRemove = <int>{};

  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  Widget _macroPill({
    required String label,
    required int value,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        '$label $value${suffix ?? ""}',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _miniLine(String left, String right, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: Colors.black87,
      fontSize: bold ? 13 : 12,
    );
    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style),
      ],
    );
  }

  Future<bool> _confirmRemove(BuildContext context, String name) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "$name" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _removeItemOptimistic({
    required BuildContext context,
    required int cartItemId,
    required String productName,
    bool showSnack = true,
  }) async {
    if (_pendingRemove.contains(cartItemId)) return;

    setState(() => _pendingRemove.add(cartItemId));

    try {
      await ref.read(removeCartItemProvider)(cartItemId);

      // Force refresh
      ref.invalidate(cartItemsProvider);

      if (showSnack && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed "$productName"')));
      }
    } catch (e) {
      // Put it back if delete failed
      if (mounted) {
        setState(() => _pendingRemove.remove(cartItemId));
      }
      ref.invalidate(cartItemsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove item.\n$e')));
      }
    }
  }

  Future<void> _changeQty({
    required BuildContext context,
    required int cartItemId,
    required int currentQty,
    required int newQty,
    required String productName,
  }) async {
    if (newQty == currentQty) return;

    if (newQty <= 0) {
      final ok = await _confirmRemove(context, productName);
      if (!ok) return;

      await _removeItemOptimistic(
        context: context,
        cartItemId: cartItemId,
        productName: productName,
        showSnack: false,
      );
      return;
    }

    try {
      await ref.read(updateCartItemQtyProvider)(
        cartItemId: cartItemId,
        quantity: newQty,
      );
      ref.invalidate(cartItemsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity.\n$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final posUserId = ref.watch(activePosUserIdProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);

    const taxRate = 0.13;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: cartItemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Failed to load cart.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          data: (items) {
            if (posUserId == null) {
              return const Center(
                child: Text(
                  'No customer selected.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            // Hide pending removed items immediately
            final visible = items
                .where((it) => !_pendingRemove.contains(it.cartItemId))
                .toList();

            if (visible.isEmpty) {
              return const Center(
                child: Text(
                  'Your cart is empty.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final subtotal = visible.fold<num>(
              0,
              (sum, it) => sum + it.lineTotal,
            );
            final tax = subtotal * taxRate;
            final total = subtotal + tax;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.black87),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Items (${visible.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            _money(subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    ...List.generate(visible.length, (index) {
                      final item = visible[index];

                      final shownLineTotal = item.lineTotal;
                      final baseSubtotal = item.baseSubtotal;
                      final addonsSubtotal = item.addonsSubtotal;

                      final cal = item.finalCaloriesPerItem;
                      final pro = item.finalProteinPerItem;
                      final carb = item.finalCarbsPerItem;
                      final fat = item.finalFatPerItem;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey('checkout_${item.cartItemId}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerRight,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (_) =>
                              _confirmRemove(context, item.productName),
                          onDismissed: (_) {
                            _removeItemOptimistic(
                              context: context,
                              cartItemId: item.cartItemId,
                              productName: item.productName,
                            );
                          },
                          child: _CartItemCard(
                            title: item.productName,
                            lineTotal: _money(shownLineTotal),
                            qty: item.quantity,
                            instructions:
                                (item.instructions ?? '').trim().isEmpty
                                ? null
                                : item.instructions!.trim(),
                            macros: [
                              _macroPill(label: 'Cal', value: cal),
                              _macroPill(
                                label: 'Protein',
                                value: pro,
                                suffix: 'g',
                              ),
                              _macroPill(
                                label: 'Carbs',
                                value: carb,
                                suffix: 'g',
                              ),
                              _macroPill(label: 'Fat', value: fat, suffix: 'g'),
                            ],
                            breakdown: Column(
                              children: [
                                _miniLine('Base', _money(baseSubtotal)),
                                const SizedBox(height: 4),
                                _miniLine('Add-ons', _money(addonsSubtotal)),
                                const SizedBox(height: 6),
                                Divider(
                                  height: 1,
                                  color: Colors.black.withOpacity(0.08),
                                ),
                                const SizedBox(height: 6),
                                _miniLine(
                                  'Total',
                                  _money(shownLineTotal),
                                  bold: true,
                                ),
                              ],
                            ),
                            variations: item.variations,
                            onRemove: () async {
                              final ok = await _confirmRemove(
                                context,
                                item.productName,
                              );
                              if (!ok) return;

                              await _removeItemOptimistic(
                                context: context,
                                cartItemId: item.cartItemId,
                                productName: item.productName,
                              );
                            },
                            onDec: () => _changeQty(
                              context: context,
                              cartItemId: item.cartItemId,
                              currentQty: item.quantity,
                              newQty: item.quantity - 1,
                              productName: item.productName,
                            ),
                            onInc: () => _changeQty(
                              context: context,
                              cartItemId: item.cartItemId,
                              currentQty: item.quantity,
                              newQty: item.quantity + 1,
                              productName: item.productName,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 16,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _miniLine('Subtotal', _money(subtotal)),
                            const SizedBox(height: 8),
                            _miniLine(
                              'Tax (${(taxRate * 100).toStringAsFixed(0)}%)',
                              _money(tax),
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            _miniLine('Total', _money(total), bold: true),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PaymentPage(total: total.toDouble()),
                                    ),
                                  );
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Pay with Card • ${_money(total)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.title,
    required this.lineTotal,
    required this.qty,
    required this.macros,
    required this.breakdown,
    required this.variations,
    required this.onRemove,
    required this.onDec,
    required this.onInc,
    this.instructions,
  });

  final String title;
  final String lineTotal;
  final int qty;
  final String? instructions;
  final List<Widget> macros;
  final Widget breakdown;
  final List<dynamic> variations;
  final VoidCallback onRemove;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final subtleBorder = Colors.black.withOpacity(0.06);
    const actionSize = 36.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= Header =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtleBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: actionSize, height: actionSize),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16.5,
                          height: 1.12,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _QtyPill(qty: qty, onDec: onDec, onInc: onInc),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: actionSize,
                    height: actionSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ================= Macros (CENTERED + SCROLLABLE) =================
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < macros.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        macros[i],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ================= Breakdown =================
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtleBorder),
            ),
            child: breakdown,
          ),

          // ================= Variations (CENTERED + SCROLLABLE) =================
          if (variations.isNotEmpty) ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < variations.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _VariationChip(v: variations[i]),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _QtyPill extends StatelessWidget {
  const _QtyPill({required this.qty, required this.onDec, required this.onInc});

  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            splashRadius: 18,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: onDec,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$qty',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            splashRadius: 18,
            icon: const Icon(Icons.add, size: 18),
            onPressed: onInc,
          ),
        ],
      ),
    );
  }
}

class _VariationChip extends StatelessWidget {
  const _VariationChip({required this.v});
  final dynamic v;

  @override
  Widget build(BuildContext context) {
    final name = (v.variationName as String?) ?? '';
    final q = (v.quantity as int?) ?? 1;
    final adj = ((v.priceAdjustment as num?) ?? 0).toDouble();

    Widget badge(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
          if (q > 1) ...[const SizedBox(width: 8), badge('x$q')],
          if (adj != 0) ...[
            const SizedBox(width: 6),
            badge('${adj >= 0 ? '+' : ''}${adj.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }
}
