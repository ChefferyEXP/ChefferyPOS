// Cheffery - cart_slider_widget.dart
//
// This is the slider that appears on the main menu. Its meant to be a pre-cart screen to overview items current in cart, change quantity, and delete them if desired

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/checkout/checkout_page.dart';

class CartSlideOver extends ConsumerStatefulWidget {
  const CartSlideOver({
    super.key,
    required this.cartCount,
    required this.onGoToCart,
  });

  final int cartCount;
  final VoidCallback onGoToCart;

  @override
  ConsumerState<CartSlideOver> createState() => _CartSlideOverState();
}

class _CartSlideOverState extends ConsumerState<CartSlideOver> {
  // Prevent "A dismissed Dismissible widget is still part of the tree"
  // by hiding rows immediately while the async remove runs.
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

      // immediately reflect deletes, this ensures it refreshes.
      ref.invalidate(cartItemsProvider);

      if (showSnack && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed "$productName"')));
      }
    } catch (e) {
      // Put the row back if the delete fails
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
      );
      return;
    }

    try {
      await ref.read(updateCartItemQtyProvider)(
        cartItemId: cartItemId,
        quantity: newQty,
      );
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
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    // Phone: 90% width. Tablet: 55%. Desktop: 40%.
    final drawerWidth = isPhone
        ? width * 0.95
        : (width < 1024 ? width * 0.55 : width * 0.40);

    final posUserId = ref.watch(activePosUserIdProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      elevation: 18,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          bottomLeft: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Cart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 18,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Items + subtotal strip
              cartItemsAsync.when(
                loading: () => _CartTopStrip(
                  leftLabel: 'Items',
                  leftValue: '${widget.cartCount}',
                  rightLabel: 'Subtotal',
                  rightValue: '—',
                ),
                error: (_, __) => _CartTopStrip(
                  leftLabel: 'Items',
                  leftValue: '${widget.cartCount}',
                  rightLabel: 'Subtotal',
                  rightValue: '—',
                ),
                data: (items) {
                  // exclude pending removed rows from subtotal
                  final visible = items
                      .where((it) => !_pendingRemove.contains(it.cartItemId))
                      .toList();

                  final subtotal = visible.fold<num>(
                    0,
                    (s, it) => s + it.lineTotal,
                  );

                  return _CartTopStrip(
                    leftLabel: 'Items',
                    leftValue: '${visible.length}',
                    rightLabel: 'Subtotal',
                    rightValue: _money(subtotal),
                    emphasizeRight: true,
                  );
                },
              ),

              const SizedBox(height: 14),

              // ===== Cart Content =====
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: posUserId == null
                      ? const Center(
                          child: Text(
                            'No customer selected.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : cartItemsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                            child: Text(
                              'Failed to load cart.\n$e',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          data: (items) {
                            // Hide pending removed rows immediately
                            final visible = items
                                .where(
                                  (it) =>
                                      !_pendingRemove.contains(it.cartItemId),
                                )
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

                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = visible[index];

                                final shownLineTotal = item.lineTotal;
                                final baseSubtotal = item.baseSubtotal;
                                final addonsSubtotal = item.addonsSubtotal;

                                final cal = item.finalCaloriesPerItem;
                                final pro = item.finalProteinPerItem;
                                final carb = item.finalCarbsPerItem;
                                final fat = item.finalFatPerItem;

                                return Dismissible(
                                  key: ValueKey('cart_${item.cartItemId}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
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
                                      _macroPill(
                                        label: 'Fat',
                                        value: fat,
                                        suffix: 'g',
                                      ),
                                    ],

                                    // Pills are placed ONLY here, under Add-ons
                                    breakdown: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _miniLine('Base', _money(baseSubtotal)),

                                        const SizedBox(height: 6),
                                        Divider(
                                          height: 1,
                                          color: Colors.black.withOpacity(0.08),
                                        ),
                                        const SizedBox(height: 6),

                                        _miniLine(
                                          'Add-ons',
                                          _money(addonsSubtotal),
                                        ),

                                        if (item.variations.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          _VariationRow(
                                            variations: item.variations,
                                          ),
                                        ],

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

                                    // kept for compatibility; card does NOT render them
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
                                );
                              },
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== Bottom: full-width checkout button only =====
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: widget.cartCount == 0
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CheckoutPage(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.black.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Go to Checkout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
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

// =========================================================
// UI widgets
// =========================================================

class _CartTopStrip extends StatelessWidget {
  const _CartTopStrip({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.emphasizeRight = false,
  });

  final String leftLabel;
  final String leftValue;

  final String rightLabel;
  final String rightValue;
  final bool emphasizeRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TopStat(
              label: leftLabel,
              value: leftValue,
              icon: Icons.shopping_cart_outlined,
              emphasize: false,
            ),
          ),
          Container(
            width: 1,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.black.withOpacity(0.08),
          ),
          Expanded(
            child: _TopStat(
              label: rightLabel,
              value: rightValue,
              icon: Icons.payments_outlined,
              emphasize: emphasizeRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  const _TopStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.emphasize,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: emphasize ? Colors.black87 : Colors.black54,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: Colors.black.withOpacity(0.55),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                  fontSize: emphasize ? 14.5 : 13.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
    required this.variations, // kept for API compatibility; NOT rendered here
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

  /// control placement of add-on pills INSIDE this widget.
  /// Put them right under the "Add-ons" line in the breakdown pass in.
  final Widget breakdown;

  /// Kept for compatibility, but the card will NOT auto-render these anymore.
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
          // Put _VariationRow inside `breakdown` under Add-ons and you're done.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtleBorder),
            ),
            child: breakdown,
          ),
        ],
      ),
    );
  }
}

class _VariationRow extends StatelessWidget {
  const _VariationRow({required this.variations});

  final List<dynamic> variations;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // 👈 force full width
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // 👈 left aligned
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < variations.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _VariationChip(v: variations[i]),
            ],
          ],
        ),
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
