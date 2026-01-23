// Cheffery - menu_models.dart
//
// This is the data structure for the menu category tabs, and the menu card tile.

class MenuCategoryTab {
  final String storeId;
  final int menuId;
  final int categoryId;
  final String label;

  const MenuCategoryTab({
    required this.storeId,
    required this.menuId,
    required this.categoryId,
    required this.label,
  });
}

class MenuCardItem {
  final String name;
  final String subtitle;
  final String calories;
  final String highlighted_feature;
  final String? image_uri;
  final String? signedImageUrl;
  final String? badgeText;

  final double base_price;

  const MenuCardItem({
    required this.name,
    required this.subtitle,
    required this.calories,
    required this.highlighted_feature,
    required this.image_uri,
    required this.base_price,
    this.signedImageUrl,
    this.badgeText,
  });

  MenuCardItem copyWith({
    String? signedImageUrl,
    String? badgeText,
    double? base_price,
  }) {
    return MenuCardItem(
      name: name,
      subtitle: subtitle,
      calories: calories,
      highlighted_feature: highlighted_feature,
      image_uri: image_uri,
      signedImageUrl: signedImageUrl ?? this.signedImageUrl,
      badgeText: badgeText ?? this.badgeText,
      base_price: base_price ?? this.base_price,
    );
  }
}
