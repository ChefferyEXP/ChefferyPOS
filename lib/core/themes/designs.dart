import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';

class AppColors {
  static const Color primary = Color(0xFF512DA8);
  static const Color accent = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color white = Colors.white;

  // New: Welcome gradient colors  
  static const Color welcomeTopGradient = Color.fromARGB(255, 192, 81, 7); // orange
  static const Color welcomeBottomGradient = Color.fromARGB(255, 4, 209, 10); // green
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 50,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.white,
  );
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

class AppPadding {
  static const EdgeInsets button = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 24,
  );
}

class AppRadii {
  static const BorderRadius button = BorderRadius.all(Radius.circular(12));
}

class ThemeCarousel extends StatelessWidget {
  final List<String> imagePaths;

  const ThemeCarousel({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: imagePaths.map((path) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(path, fit: BoxFit.cover, width: double.infinity),
        );
      }).toList(),
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        enlargeFactor: 0.3,
        aspectRatio: 16 / 9,
      ),
    );
  }
}
