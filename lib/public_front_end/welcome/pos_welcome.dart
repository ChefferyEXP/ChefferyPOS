// Cheffery - pos_welcome.dart
//
// This page is designed as the home screen from the POS public front end.
// Tap anywhere on screen to proceed to phone number entry

import 'package:flutter/material.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  final List<String> _logos = [
    'assets/logos/freshBlendzLogo.png',
    'assets/logos/cheffery.png',
  ];

  void _handleTap() {
    Navigator.pushNamed(context, '/get_user_phonenumber');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // --- Gradient background ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, // where the gradient starts
                    end: Alignment.bottomRight, // where it ends
                    colors: [
                      AppColors.welcomeTopGradient,
                      AppColors.welcomeBottomGradient,
                    ],
                    stops: [
                      0.3,
                      4.0,
                    ], // top color dominates 70%, bottom color mixes in at 70%
                  ),
                ),
              ),

              // --- Centered logos & title ---
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(_logos[1], width: 200, height: 200),
                        const SizedBox(width: 24),
                        Image.asset(_logos[0], width: 300, height: 300),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Cheffery POS', style: AppTextStyles.title),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap anywhere to begin',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
