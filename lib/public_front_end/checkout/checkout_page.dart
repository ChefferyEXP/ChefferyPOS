// Cheffery - checkout_page.dart
//
// Checkout page to display all items added by the user, show details of cost, and proceed to payment, UI needs some work

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_provider.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: use your actual providers
    final posUserId = ref.watch(activePosUserIdProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);

    const taxRate = 0.13; // Ontario HST (change later if needed)

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

            if (items.isEmpty) {
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

            // ---- totals ----
            final subtotal = items.fold<num>(
              0,
              (sum, it) => sum + it.lineTotal,
            );
            final tax = subtotal * taxRate;
            final total = subtotal + tax;

            return Stack(
              children: [
                // =========================
                // Scrollable content
                // =========================
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
                              'Items (${items.length})',
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

                    // =========================
                    // Cart items
                    // =========================
                    ...List.generate(items.length, (index) {
                      final item = items[index];

                      final shownLineTotal = item.lineTotal;
                      final baseSubtotal = item.baseSubtotal;
                      final addonsSubtotal = item.addonsSubtotal;

                      final cal = item.finalCaloriesLine;
                      final pro = item.finalProteinLine;
                      final carb = item.finalCarbsLine;
                      final fat = item.finalFatLine;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _money(shownLineTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
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
                              const SizedBox(height: 8),
                              Text(
                                item.instructions!.trim(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _macroPill(label: 'Cal', value: cal),
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

                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  _miniLine('Base', _money(baseSubtotal)),
                                  const SizedBox(height: 6),
                                  _miniLine('Add-ons', _money(addonsSubtotal)),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  _miniLine(
                                    'Line Total',
                                    _money(shownLineTotal),
                                    bold: true,
                                  ),
                                ],
                              ),
                            ),

                            if (item.variations.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: item.variations.map((v) {
                                  final qtyPart = v.quantity > 1
                                      ? ' x${v.quantity}'
                                      : '';
                                  final pricePart = v.priceAdjustment == 0
                                      ? ''
                                      : ' (${v.priceAdjustment >= 0 ? '+' : ''}${v.priceAdjustment.toStringAsFixed(2)})';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFF2E7D32),
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
                      );
                    }),
                  ],
                ),

                // =========================
                // bottom summary
                // =========================
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
                                  // TODO: Hook up Stripe / payment later
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pay (coming soon)'),
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
                                  'Pay • ${_money(total)}',
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
