// Cheffery - payment_page.dart
//
// WIP
// This page is what will send the total amount for the order to square/stripe. If payment succeeds, order will be created.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/order_flow_providers.dart'
    as flow;

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.total});

  final double total;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with SingleTickerProviderStateMixin {
  static const Color welcomeTopGradient = Color.fromARGB(255, 192, 81, 7);
  static const Color welcomeBottomGradient = Color.fromARGB(255, 4, 209, 10);

  static const List<String> _logos = [
    'assets/logos/freshBlendzLogo.png',
    'assets/logos/cheffery.png',
  ];

  static const double _taxRate = 0.13;

  late final AnimationController _controller;

  String _money(num v) => '\$${v.toStringAsFixed(2)}';
  static const double _twoPi = 6.283185307179586;

  bool _markingPaid = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _logoInside(String assetPath) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }

  Future<void> _paymentSuccess() async {
    if (_markingPaid) return;
    setState(() => _markingPaid = true);

    try {
      // IMPORTANT: get the CURRENT cart order id
      final int? orderId = await ref.read(flow.currentOrderIdProvider.future);

      if (orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active order (missing user/store).'),
          ),
        );
        return;
      }

      // 1) Mark order placed (payment success)
      await ref.read(flow.markOrderPlacedProvider)(
        orderId: orderId,
        total: widget.total,
        taxRate: _taxRate,
      );

      // 2) DO NOT clear cart here.
      // The store monitor + CurrentOrderPage rely on user_cart rows
      // until the store presses "Complete Order".

      // 3) Refresh anything that might show cart/order state
      ref.invalidate(flow.orderByIdProvider(orderId));
      ref.invalidate(flow.orderLinesByOrderIdProvider(orderId));
      ref.invalidate(flow.currentOrderIdProvider);

      // Optionally refresh the cart badge:
      // ref.invalidate(cart.cartItemsProvider);
      // ref.invalidate(cart.cartCountProvider);

      // 4) Go back to welcome
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark payment success.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _markingPaid = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double outerSize = 240;
    const double ringThickness = 10;
    const double cardW = 160;
    const double cardH = 100;
    const double spinPad = 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _markingPaid ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Waiting for payment',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final ringAngle = _controller.value * _twoPi;
                            final breathe01 = (1 + math.sin(ringAngle)) / 2;
                            final t = Curves.easeInOut.transform(breathe01);

                            final scale = 0.94 + (0.06 * t);
                            final shadowBlur = 12 + (6 * t);
                            final shadowY = 8 + (4 * t);
                            final shadowOpacity = 0.07 + (0.03 * t);

                            return SizedBox(
                              width: outerSize + spinPad,
                              height: outerSize + spinPad,
                              child: Center(
                                child: SizedBox(
                                  width: outerSize,
                                  height: outerSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.rotate(
                                        angle: ringAngle,
                                        child: Container(
                                          width: outerSize,
                                          height: outerSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                welcomeTopGradient,
                                                welcomeBottomGradient,
                                                welcomeTopGradient,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 18,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: outerSize - (ringThickness * 2),
                                        height: outerSize - (ringThickness * 2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: cardW,
                                          height: cardH,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              width: 1.1,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                Colors.black.withOpacity(0.03),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  shadowOpacity,
                                                ),
                                                blurRadius: shadowBlur,
                                                offset: Offset(0, shadowY),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left: -40,
                                                  top: -30,
                                                  child: Transform.rotate(
                                                    angle: 0.35,
                                                    child: Container(
                                                      width: 120,
                                                      height: 200,
                                                      color: Colors.white
                                                          .withOpacity(0.18),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        12,
                                                        12,
                                                        12,
                                                        12,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Container(
                                                        height: 14,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.16,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          _logoInside(
                                                            _logos[0],
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                'Cheffery POS',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  fontSize: 8,
                                                                  letterSpacing:
                                                                      0.4,
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.72,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          _logoInside(
                                                            _logos[1],
                                                          ),
                                                        ],
                                                      ),
                                                      const Spacer(),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _money(widget.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _markingPaid ? null : _paymentSuccess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _markingPaid
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Payment Success',
                                    style: TextStyle(
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
            );
          },
        ),
      ),
    );
  }
}
