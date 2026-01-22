// Cheffery - cart_slider_widget.dart
//
// This is the slider that appears on the main menu. Its meant to be a pre-cart screen to overview items current in cart, change quantity, and delete them if desired

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/checkout/checkout_page.dart';

class CartSlideOver extends ConsumerWidget {
  const CartSlideOver({
    super.key,
    required this.cartCount,
    required this.onGoToCart,
  });

  final int cartCount;
  final VoidCallback onGoToCart;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width * 0.40;

    final posUserId = ref.watch(activePosUserIdProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);

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
              // ===== Header =====
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

              // ===== Cart Content =====
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: posUserId == null
                      ? const Center(
                          child: Text(
                            'No customer selected.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Your cart is empty.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = items[index];

                                final shownLineTotal = item.lineTotal;
                                final baseSubtotal = item.baseSubtotal;
                                final addonsSubtotal = item.addonsSubtotal;

                                final cal = item.finalCaloriesLine;
                                final pro = item.finalProteinLine;
                                final carb = item.finalCarbsLine;
                                final fat = item.finalFatLine;

                                // Swipe-to-delete
                                return Dismissible(
                                  key: ValueKey('cart_${item.cartItemId}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(12),
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
                                  onDismissed: (_) async {
                                    try {
                                      await ref.read(removeCartItemProvider)(
                                        item.cartItemId,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Removed "${item.productName}"',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // If delete fails, re-fetch will restore item
                                      ref.invalidate(cartItemsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to remove item.\n$e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ===== Title row + trash button =====
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _money(shownLineTotal),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              tooltip: 'Remove',
                                              onPressed: () async {
                                                final ok = await _confirmRemove(
                                                  context,
                                                  item.productName,
                                                );
                                                if (!ok) return;

                                                try {
                                                  await ref.read(
                                                    removeCartItemProvider,
                                                  )(item.cartItemId);
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to remove item.\n$e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              splashRadius: 18,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          'Qty: ${item.quantity}  •  ${_money(shownLineTotal / item.quantity)} each',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                        if ((item.instructions ?? '')
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            item.instructions!.trim(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 10),

                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Row(
                                            children: [
                                              _macroPill(
                                                label: 'Cal',
                                                value: cal,
                                              ),
                                              const SizedBox(width: 8),
                                              _macroPill(
                                                label: 'Protein',
                                                value: pro,
                                                suffix: 'g',
                                              ),
                                              const SizedBox(width: 8),
                                              _macroPill(
                                                label: 'Carbs',
                                                value: carb,
                                                suffix: 'g',
                                              ),
                                              const SizedBox(width: 8),
                                              _macroPill(
                                                label: 'Fat',
                                                value: fat,
                                                suffix: 'g',
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF6F6F6),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              _miniLine(
                                                'Base',
                                                _money(baseSubtotal),
                                              ),
                                              const SizedBox(height: 4),
                                              _miniLine(
                                                'Add-ons',
                                                _money(addonsSubtotal),
                                              ),
                                              const SizedBox(height: 6),
                                              const Divider(height: 1),
                                              const SizedBox(height: 6),
                                              _miniLine(
                                                'Total',
                                                _money(shownLineTotal),
                                                bold: true,
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (item.variations.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: item.variations.map((v) {
                                              final qtyPart = v.quantity > 1
                                                  ? ' x${v.quantity}'
                                                  : '';
                                              final pricePart =
                                                  v.priceAdjustment == 0
                                                  ? ''
                                                  : ' (${v.priceAdjustment >= 0 ? '+' : ''}${v.priceAdjustment.toStringAsFixed(2)})';

                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE8F5E9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2E7D32,
                                                    ),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${v.variationName}$qtyPart$pricePart',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black87,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
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

              // ===== Go to Checkout =====
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: cartCount == 0
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Checkout',
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
