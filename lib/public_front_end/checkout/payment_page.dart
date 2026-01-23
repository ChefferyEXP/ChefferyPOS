// Cheffery - payment_page.dart
//
// WIP
// This page is what will send the total amount for the order to square/stripe. If payment succeeds, order will be created.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  late final AnimationController _controller;

  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    const double outerSize = 240;
    const double ringThickness = 10;

    const double cardW = 160;
    const double cardH = 100;

    // Extra room so rotation + shadows never overflow
    const double spinPad = 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      // scroll + keep centered when there’s room
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
                            return Transform.rotate(
                              angle:
                                  _controller.value * 6.283185307179586, // 2π
                              child: SizedBox(
                                width: outerSize + spinPad,
                                height: outerSize + spinPad,
                                child: Center(
                                  child: SizedBox(
                                    width: outerSize,
                                    height: outerSize,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Gradient ring
                                        Container(
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

                                        // Inner white cutout
                                        Container(
                                          width:
                                              outerSize - (ringThickness * 2),
                                          height:
                                              outerSize - (ringThickness * 2),
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

                                        // Card
                                        Container(
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
                                                  0.08,
                                                ),
                                                blurRadius: 14,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            child: Stack(
                                              children: [
                                                // subtle highlight sheen
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

                                                //make the internal layout fit the fixed card height
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        12,
                                                        12,
                                                        12,
                                                        12,
                                                      ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      // Mag stripe
                                                      Container(
                                                        height:
                                                            14, // slightly smaller
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

                                                      // Logos + text (kept)
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

                                                      const SizedBox(height: 6),

                                                      Flexible(
                                                        child: Align(
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 32,
                                                                height: 22,
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.06,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                  border: Border.all(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                          0.10,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      height: 6,
                                                                      width: 70,
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                              0.06,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              99,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 5,
                                                                    ),
                                                                    Container(
                                                                      height: 6,
                                                                      width: 95,
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                              0.05,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              99,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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
