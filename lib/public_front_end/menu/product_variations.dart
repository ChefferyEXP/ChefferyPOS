// Cheffery - product_variations.dart
//
// This is the customization for the variations of an item
// It takes the product id from the menu tile tapped, and fetches the variation data from the database
// Will in future, use the add cart button to put the product, and its selected variations in the users cart.
// Importantly, this page also displays all of the meta data for the item, and as you add variations, the price increases, and later the meta data will too

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/public_front_end/menu/menu_models.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';

class ProductVariationsPage extends ConsumerStatefulWidget {
  const ProductVariationsPage({
    super.key,
    required this.item,
    required this.productId,
  });

  final MenuCardItem item;
  final int productId;

  @override
  ConsumerState<ProductVariationsPage> createState() =>
      _ProductVariationsPageState();
}

class _ProductVariationsPageState extends ConsumerState<ProductVariationsPage> {
  bool _loading = true;
  String? _error;

  // Loaded from store_menu_products
  Map<String, dynamic>? _productRow;

  // Variation groups built from DB
  final List<_VariationGroupVM> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final productId = widget.productId;

      // 1) Product base details
      final row = await supabase
          .from('store_menu_products')
          .select(
            'product_id,name,subtitle,description,base_price,calories,protein,carbs,fat,image_uri,highlighted_feature',
          )
          .eq('product_id', productId)
          .maybeSingle();

      if (row == null) {
        throw Exception('Product not found (product_id=$productId)');
      }
      _productRow = Map<String, dynamic>.from(row as Map);

      // 2) Variation types assigned to this product (groups)
      final groupRows = await supabase
          .from('menu_item_variation_groups_junction')
          .select(
            'variation_type_id_product_variation_type, product_variation_type (variation_type_id,name,description,min_selection,max_selection)',
          )
          .eq('product_id_store_menu_products', productId);

      final List<Map<String, dynamic>> groupList = (groupRows as List)
          .cast<Map<String, dynamic>>();

      // Build a map of variationTypeId -> group meta
      final Map<int, _GroupMeta> groupMetaByTypeId = {};
      for (final gr in groupList) {
        final embedded = gr['product_variation_type'];
        if (embedded is Map) {
          final m = Map<String, dynamic>.from(embedded);
          final typeId =
              (m['variation_type_id'] as int?) ??
              (gr['variation_type_id_product_variation_type'] as int?);
          if (typeId == null) continue;

          groupMetaByTypeId[typeId] = _GroupMeta(
            variationTypeId: typeId,
            title: (m['name'] ?? '').toString(),
            description: (m['description'] as String?)?.toString(),
            min: (m['min_selection'] as int?) ?? 0,
            max: (m['max_selection'] as int?) ?? 0,
          );
        } else {
          final typeId = gr['variation_type_id_product_variation_type'] as int?;
          if (typeId == null) continue;
          groupMetaByTypeId.putIfAbsent(
            typeId,
            () => _GroupMeta(
              variationTypeId: typeId,
              title: 'Options',
              description: null,
              min: 0,
              max: 0,
            ),
          );
        }
      }

      // 3) Allowed variations for this product (options)
      final allowedRows = await supabase
          .from('product_allowed_variations')
          .select(
            'variation_id,is_default,default_quantity,sort_order, variations (variation_id,name,description,price_adjustment,calories,protein,fat,carbs,variation_type_id_product_variation_type)',
          )
          .eq('product_id', productId)
          .order('sort_order', ascending: true);

      final allowedList = (allowedRows as List).cast<Map<String, dynamic>>();

      // Group options by variation_type_id
      final Map<int, List<_VariationOptionVM>> optionsByTypeId = {};

      for (final ar in allowedList) {
        final v = ar['variations'];
        if (v is! Map) continue;
        final vm = Map<String, dynamic>.from(v);

        final typeId = vm['variation_type_id_product_variation_type'] as int?;
        if (typeId == null) continue;

        final variationId = vm['variation_id'] as int;
        final name = (vm['name'] ?? '').toString();
        final desc = (vm['description'] as String?)?.toString();

        final priceAdjNum = vm['price_adjustment'];
        final priceDelta = (priceAdjNum is num) ? priceAdjNum.toDouble() : 0.0;

        final isDefault = (ar['is_default'] as bool?) ?? false;
        final defaultQty = (ar['default_quantity'] as int?) ?? 1;

        final qty = isDefault ? defaultQty : 0;

        optionsByTypeId
            .putIfAbsent(typeId, () => [])
            .add(
              _VariationOptionVM(
                id: variationId,
                name: name,
                description: desc,
                priceDelta: priceDelta,
                isDefault: isDefault,
                quantity: qty,
              ),
            );
      }

      // Build final groups list in a stable order
      _groups.clear();

      final typeIds = groupMetaByTypeId.keys.toList()..sort();
      for (final typeId in typeIds) {
        final meta = groupMetaByTypeId[typeId]!;
        final opts = optionsByTypeId[typeId] ?? const [];

        // Enforce single-select default sanity: if max==1, keep only first default
        if (meta.max == 1) {
          bool found = false;
          for (final o in opts) {
            if (o.quantity > 0) {
              if (!found) {
                o.quantity = 1;
                found = true;
              } else {
                o.quantity = 0;
              }
            }
          }
          // If min==1 and none selected, auto-select first option
          if (meta.min == 1 && !found && opts.isNotEmpty) {
            opts.first.quantity = 1;
          }
        }

        _groups.add(
          _VariationGroupVM(
            title: meta.title.isEmpty ? 'Options' : meta.title,
            description: meta.description,
            min: meta.min,
            max: meta.max,
            options: opts,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // --- UI actions ---
  void _toggleSingleSelect(_VariationGroupVM group, _VariationOptionVM opt) {
    if (group.max == 1) {
      for (final o in group.options) {
        o.quantity = 0;
      }
      opt.quantity = 1;
    } else {
      opt.quantity = (opt.quantity > 0) ? 0 : 1;
    }
    setState(() {});
  }

  void _inc(_VariationGroupVM group, _VariationOptionVM opt) {
    final current = group.options.fold<int>(0, (s, o) => s + o.quantity);
    if (group.max > 0 && current >= group.max) return;
    opt.quantity += 1;
    setState(() {});
  }

  void _dec(_VariationOptionVM opt) {
    if (opt.quantity <= 0) return;
    opt.quantity -= 1;
    setState(() {});
  }

  double _addonsPrice() {
    double sum = 0;
    for (final g in _groups) {
      for (final o in g.options) {
        if (o.quantity > 0) {
          sum += (o.priceDelta * o.quantity);
        }
      }
    }
    return sum;
  }

  double _basePrice() {
    final row = _productRow;
    if (row == null) return 0;
    final v = row['base_price'];
    if (v is num) return v.toDouble();
    return 0;
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final menuItem = widget.item;
    final row = _productRow;

    final base = _basePrice();
    final addons = _addonsPrice();
    final total = base + addons;

    final title = (row?['name'] ?? menuItem.name).toString();
    final subtitle = (row?['subtitle'] ?? menuItem.subtitle).toString();
    final description = (row?['description'] ?? '').toString();

    final calories = row?['calories'];
    final protein = row?['protein'];
    final carbs = row?['carbs'];
    final fat = row?['fat'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAEEA00), Color(0xFF00C853)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Top bar =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadAll,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ===== Content =====
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CompactProductCard(
                        item: menuItem,
                        title: title,
                        subtitle: subtitle,
                        description: description,
                        basePrice: base,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                      ),
                      const SizedBox(height: 12),

                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Failed to load variations.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      else if (_groups.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'No variations for this product.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      else
                        ..._groups.map(
                          (g) => _VariationGroupCard(
                            group: g,
                            onToggle: (opt) => _toggleSingleSelect(g, opt),
                            onInc: (opt) => _inc(g, opt),
                            onDec: (opt) => _dec(opt),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ===== Bottom price bar =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PriceLine(label: 'Base', value: _money(base)),
                            const SizedBox(height: 4),
                            _PriceLine(
                              label: 'Add-ons',
                              value: addons == 0
                                  ? _money(0)
                                  : '+ ${_money(addons)}',
                            ),
                            const SizedBox(height: 8),
                            _PriceLine(
                              label: 'Final',
                              value: _money(total),
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add to cart coming next.'),
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
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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

// Top of page product cart with image and meta data
class _CompactProductCard extends StatelessWidget {
  const _CompactProductCard({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.basePrice,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final MenuCardItem item;
  final String title;
  final String subtitle;
  final String description;
  final double basePrice;
  final dynamic calories;
  final dynamic protein;
  final dynamic carbs;
  final dynamic fat;

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final url = item.signedImageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small image
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasUrl
                ? Image(
                    image: NetworkImage(url),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/logos/freshBlendzLogo.png', // Use freshblendz logo as fall back if failure on load.
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    'assets/logos/freshBlendzLogo.png',
                    fit: BoxFit.contain,
                  ),
          ),

          const SizedBox(width: 12),

          // Text / specs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black54,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipPill(text: 'Base ${_money(basePrice)}'),
                    if (calories != null) _ChipPill(text: '${calories} cal'),
                    if (protein != null) _ChipPill(text: '${protein}g protein'),
                    if (carbs != null) _ChipPill(text: '${carbs}g carbs'),
                    if (fat != null) _ChipPill(text: '${fat}g fat'),
                  ],
                ),

                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Chip pill for the meta data
class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// Bottom price line UI
class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
      color: Colors.black87,
    );

    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: style)),
        Expanded(
          child: Text(value, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }
}

// Variation card
class _VariationGroupCard extends StatelessWidget {
  const _VariationGroupCard({
    required this.group,
    required this.onToggle,
    required this.onInc,
    required this.onDec,
  });

  final _VariationGroupVM group;
  final void Function(_VariationOptionVM opt) onToggle;
  final void Function(_VariationOptionVM opt) onInc;
  final void Function(_VariationOptionVM opt) onDec;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.description ??
                  _selectionHint(min: group.min, max: group.max),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            ...group.options.map((opt) {
              final selected = opt.quantity > 0;
              final delta = opt.priceDelta;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2E7D32)
                        : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  onTap: () => onToggle(opt),
                  title: Text(
                    opt.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle:
                      (delta != 0 ||
                          (opt.description?.trim().isNotEmpty ?? false))
                      ? Text(
                          [
                            if (delta != 0)
                              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}',
                            if (opt.description?.trim().isNotEmpty ?? false)
                              opt.description!.trim(),
                          ].join(' • '),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                  trailing: group.max == 1
                      ? Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected
                              ? const Color(0xFF2E7D32)
                              : Colors.black45,
                        )
                      : _QtyStepper(
                          qty: opt.quantity,
                          onDec: () => onDec(opt),
                          onInc: () => onInc(opt),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _selectionHint({required int min, required int max}) {
    if (max <= 0 && min <= 0) return 'Optional';
    if (max <= 0) return 'Choose at least $min';
    if (min <= 0) return 'Choose up to $max';
    if (min == max) return 'Choose $min';
    return 'Choose $min-$max';
  }
}

// Quantity selectors
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
  });

  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: qty > 0 ? onDec : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
        IconButton(
          onPressed: onInc,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

// =========================================================
// Temporary view-models
// =========================================================

class _GroupMeta {
  _GroupMeta({
    required this.variationTypeId,
    required this.title,
    required this.description,
    required this.min,
    required this.max,
  });

  final int variationTypeId;
  final String title;
  final String? description;
  final int min;
  final int max;
}

class _VariationGroupVM {
  _VariationGroupVM({
    required this.title,
    required this.options,
    this.description,
    this.min = 0,
    this.max = 0,
  });

  final String title;
  final String? description;
  final int min;
  final int max;
  final List<_VariationOptionVM> options;
}

class _VariationOptionVM {
  _VariationOptionVM({
    required this.id,
    required this.name,
    required this.priceDelta,
    required this.isDefault,
    required this.quantity,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
  final double priceDelta;
  final bool isDefault;
  int quantity;
}
