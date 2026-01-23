import 'package:flutter/material.dart';
import 'menu_models.dart';

import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item, required this.onTap});

  final MenuCardItem item;
  final VoidCallback onTap;

  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final title = item.name.trim();
    final subtitle = item.subtitle.trim();
    final calories = item.calories.trim();
    final feature = item.highlighted_feature.trim();

    final isPhone = MediaQuery.sizeOf(context).width < 600;

    final artworkFlex = 6;
    final textFlex = isPhone ? 4 : 4;

    // more padding on larger devices
    final pad = isPhone ? 10.0 : 12.0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FFD9), Color(0xFFE7FFAE)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Artwork =====
            Expanded(
              flex: artworkFlex,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CardArtwork(item: item),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.00),
                            Colors.black.withOpacity(0.08),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _Pill(
                      child: Text(
                        _money(item.base_price),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  if (item.badgeText != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          item.badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ===== Text =====
            Expanded(
              flex: textFlex,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // If the text area is short (small phones / smaller grid cells),
                  // tighten by a couple pixels to prevent overflow
                  final tight = isPhone && constraints.maxHeight < 150;

                  final topPad = tight ? 7.0 : (isPhone ? 8.0 : 10.0);
                  final bottomPad = tight ? 7.0 : (isPhone ? 8.0 : 10.0);
                  final titleFont = tight ? 14.8 : (isPhone ? 15.2 : 16.5);
                  final featureFont = tight ? 11.6 : (isPhone ? 12.0 : 13.0);
                  final midGap = tight ? 5.0 : (isPhone ? 6.0 : 10.0);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(pad, topPad, pad, bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFont,
                            height: 1.10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF165B2C),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: isPhone ? 4 : 6),

                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isPhone ? 12.0 : 13.0,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF165B2C).withOpacity(0.75),
                              letterSpacing: 0.15,
                            ),
                          ),

                        SizedBox(height: midGap),

                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (calories.isNotEmpty)
                                  Text(
                                    calories,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isPhone ? 11.2 : 12,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF245B2F),
                                    ),
                                  ),
                                if (calories.isNotEmpty)
                                  SizedBox(
                                    height: tight ? 2 : (isPhone ? 3 : 6),
                                  ),
                                if (feature.isNotEmpty)
                                  Text(
                                    feature,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: featureFont,
                                      height: tight ? 1.06 : 1.10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2C6B38),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Art work on top
class _CardArtwork extends StatelessWidget {
  const _CardArtwork({required this.item});
  final MenuCardItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.signedImageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return Container(
      color: Colors.white.withOpacity(0.25),
      child: hasUrl
          ? Image(
              image: NetworkImage(url),
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/logos/freshBlendzLogo.png',
                fit: BoxFit.contain,
              ),
            )
          : Image.asset(
              'assets/logos/freshBlendzLogo.png',
              fit: BoxFit.contain,
            ),
    );
  }
}
