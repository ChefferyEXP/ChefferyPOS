import 'package:flutter/material.dart';
import 'menu_models.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item, required this.onTap});

  final MenuCardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3FFCF), Color(0xFFE6FFA9)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Artwork allocation
            Expanded(
              flex: 6, //60% of the tile
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CardArtwork(item: item),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 26,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.10),
                          ],
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
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(999),
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
            Expanded(
              flex: 4, // 40% of tile
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 8), // Space from image at top
                    // Text for the menu tile details
                    Text(
                      item.name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E6B2E),
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      item.subtitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E6B2E),
                        letterSpacing: 0.9,
                      ),
                    ),
                    Text(
                      item.calories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF245B2F),
                      ),
                    ),
                    Text(
                      item.highlighted_feature,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C6B38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Art work on top 60% of the card
// If the image from supabase fails to load, then it will default to the FreshBlendzLogo
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
