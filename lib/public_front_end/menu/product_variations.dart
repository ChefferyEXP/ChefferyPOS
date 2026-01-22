// Cheffery - product_variations.dart
//
// This is the customization for the variations of an item
// It takes the product id from the menu tile tapped, and fetches the variation data from the database
// use the add cart button to put the product, and its selected variations in the users cart.
// Importantly, this page also displays all of the meta data for the item, and as you add variations, the price increases, and the meta data will too

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/public_front_end/menu/menu_models.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/pos_user_provider.dart';
import 'package:v0_0_0_cheffery_pos/public_front_end/cart/cart_provider.dart';

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

  bool _adding = false;

  // user-selected quantity to add
  int _cartQty = 1;

  // Loaded from store_menu_products
  Map<String, dynamic>? _productRow;

  // Variation groups built from DB
  final List<_VariationGroupVM> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // =========================================================
  // Helpers: Supabase can return num / int / double / string
  // =========================================================

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  double _num(dynamic v) => (v is num)
      ? v.toDouble()
      : (v is String ? (double.tryParse(v.trim()) ?? 0.0) : 0.0);

  // =========================================================
  // Load: product + groups + options
  // =========================================================

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

          final typeId = _toInt(
            m['variation_type_id'] ??
                gr['variation_type_id_product_variation_type'],
            fallback: -1,
          );
          if (typeId <= 0) continue;

          final minSel = _toInt(m['min_selection'], fallback: 0);

          // max_selection "per option max qty", NOT group total max qty
          final maxSel = _toInt(m['max_selection'], fallback: 0);

          groupMetaByTypeId[typeId] = _GroupMeta(
            variationTypeId: typeId,
            title: (m['name'] ?? '').toString(),
            description: (m['description'] as String?)?.toString(),
            min: minSel,
            max: maxSel,
          );
        } else {
          final typeId = _toInt(
            gr['variation_type_id_product_variation_type'],
            fallback: -1,
          );
          if (typeId <= 0) continue;

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

        final typeId = _toInt(
          vm['variation_type_id_product_variation_type'],
          fallback: -1,
        );
        if (typeId <= 0) continue;

        final variationId = _toInt(vm['variation_id'], fallback: -1);
        if (variationId <= 0) continue;

        final name = (vm['name'] ?? '').toString();
        final desc = (vm['description'] as String?)?.toString();

        final priceDelta = _toDouble(vm['price_adjustment'], fallback: 0);

        // Nutrition
        final calories = _toDouble(vm['calories'], fallback: 0);
        final protein = _toDouble(vm['protein'], fallback: 0);
        final carbs = _toDouble(vm['carbs'], fallback: 0);
        final fat = _toDouble(vm['fat'], fallback: 0);

        final isDefault = (ar['is_default'] as bool?) ?? false;
        final defaultQty = _toInt(ar['default_quantity'], fallback: 1);
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
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
            );
      }

      // Build final groups list in a stable order
      _groups.clear();

      final typeIds = groupMetaByTypeId.keys.toList()..sort();
      for (final typeId in typeIds) {
        final meta = groupMetaByTypeId[typeId]!;
        final opts = optionsByTypeId[typeId] ?? <_VariationOptionVM>[];

        // Radio group sanity: if max==1, keep only first default
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
        } else {
          // meta.max is PER OPTION, so clamp each options default qty individually
          if (meta.max > 0) {
            for (final o in opts) {
              if (o.quantity > meta.max) o.quantity = meta.max;
            }
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

  // =========================================================
  // Selection rules
  // - MIN is still group-level total quantity (sum of quantities in group)
  // - MAX is per-option quantity cap (except max==1 radio groups)
  // =========================================================

  int _qtySum(_VariationGroupVM group) {
    return group.options.fold<int>(0, (s, o) => s + o.quantity);
  }

  String? _validateSelections() {
    for (final g in _groups) {
      final sumQty = _qtySum(g);

      // MIN is still group-level
      if (g.min > 0 && sumQty < g.min) {
        return 'Please choose at least ${g.min} item(s) for "${g.title}".';
      }
    }
    return null;
  }

  // --- UI actions ---
  void _toggleSingleSelect(_VariationGroupVM group, _VariationOptionVM opt) {
    // Radio group (max == 1 means single-select)
    if (group.max == 1) {
      // Required single-select group: do not allow going to zero
      if (group.min == 1 && opt.quantity > 0) return;

      for (final o in group.options) {
        o.quantity = 0;
      }
      opt.quantity = 1;
      setState(() {});
      return;
    }

    // Non-radio group: toggle 0 <-> 1 (still respects min; max is per-option)
    if (opt.quantity > 0) {
      // turning OFF: ensure not violating min
      if (group.min > 0) {
        final sumQty = _qtySum(group);
        if (sumQty <= group.min) return; // would go below min
      }
      opt.quantity = 0;
    } else {
      // per-option max check (only relevant if max == 0? unlimited)
      if (group.max > 0 && 1 > group.max) return;
      opt.quantity = 1;
    }

    setState(() {});
  }

  void _inc(_VariationGroupVM group, _VariationOptionVM opt) {
    // Radio group: keep as 0/1
    if (group.max == 1) {
      _toggleSingleSelect(group, opt);
      return;
    }

    // per-option max (NOT group sum)
    if (group.max > 0 && opt.quantity >= group.max) return;

    opt.quantity += 1;
    setState(() {});
  }

  void _dec(_VariationGroupVM group, _VariationOptionVM opt) {
    if (opt.quantity <= 0) return;

    // Radio group: do not allow going to 0 if required
    if (group.max == 1) {
      if (group.min == 1) return;
      opt.quantity = 0;
      setState(() {});
      return;
    }

    // If this would reduce group sum below min, block
    if (group.min > 0) {
      final sumQty = _qtySum(group);
      if (sumQty <= group.min) return;
    }

    opt.quantity -= 1;
    setState(() {});
  }

  // cart quantity stepper
  void _incCartQty() => setState(() => _cartQty = (_cartQty + 1).clamp(1, 99));
  void _decCartQty() => setState(() => _cartQty = (_cartQty - 1).clamp(1, 99));

  double _basePrice() {
    final row = _productRow;
    if (row == null) return 0;
    return _toDouble(row['base_price'], fallback: 0);
  }

  // ---- Totals (base + selected variations) ----
  _Totals _computeTotals() {
    final row = _productRow;

    final basePrice = _basePrice();
    final baseCal = _num(row?['calories']);
    final baseProtein = _num(row?['protein']);
    final baseCarbs = _num(row?['carbs']);
    final baseFat = _num(row?['fat']);

    double addonsPrice = 0;
    double addonsCal = 0;
    double addonsProtein = 0;
    double addonsCarbs = 0;
    double addonsFat = 0;

    final selected = <_SelectedOpt>[];

    for (final g in _groups) {
      for (final o in g.options) {
        if (o.quantity > 0) {
          final q = o.quantity;
          addonsPrice += (o.priceDelta * q);
          addonsCal += (o.calories * q);
          addonsProtein += (o.protein * q);
          addonsCarbs += (o.carbs * q);
          addonsFat += (o.fat * q);

          selected.add(
            _SelectedOpt(
              name: o.name,
              qty: q,
              priceDelta: o.priceDelta,
              calories: o.calories,
              protein: o.protein,
              carbs: o.carbs,
              fat: o.fat,
            ),
          );
        }
      }
    }

    return _Totals(
      basePrice: basePrice,
      addonsPrice: addonsPrice,
      finalPrice: basePrice + addonsPrice,
      baseCalories: baseCal,
      baseProtein: baseProtein,
      baseCarbs: baseCarbs,
      baseFat: baseFat,
      addonsCalories: addonsCal,
      addonsProtein: addonsProtein,
      addonsCarbs: addonsCarbs,
      addonsFat: addonsFat,
      finalCalories: baseCal + addonsCal,
      finalProtein: baseProtein + addonsProtein,
      finalCarbs: baseCarbs + addonsCarbs,
      finalFat: baseFat + addonsFat,
      selected: selected,
    );
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  String _buildVariationSummary(_Totals totals) {
    if (totals.selected.isEmpty) return '';
    return totals.selected
        .map((s) => s.qty > 1 ? '${s.name} x${s.qty}' : s.name)
        .join(', ');
  }

  Future<void> _addToCart(_Totals totals) async {
    if (_adding) return;

    final posUserId = ref.read(activePosUserIdProvider);
    if (posUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No customer selected.')));
      return;
    }

    final ruleError = _validateSelections();
    if (ruleError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ruleError)));
      return;
    }

    final row = _productRow ?? {};
    final productName = (row['name'] ?? widget.item.name).toString();
    final productDescription = (row['description'] as String?)?.toString();

    // Base snapshot (per 1 item)
    final basePrice = totals.basePrice;
    final baseCalories = totals.baseCalories.round();
    final baseProtein = totals.baseProtein.round();
    final baseCarbs = totals.baseCarbs.round();
    final baseFat = totals.baseFat.round();

    // Final price for ONE configured item (base + add-ons)
    final perItemFinalPrice = totals.finalPrice;

    // user-selected quantity
    final cartQty = _cartQty;

    // Optional display summary
    final instructions = _buildVariationSummary(totals);

    // Build variation snapshot rows using REAL variation IDs
    final selectedVariations = <Map<String, dynamic>>[];
    for (final g in _groups) {
      for (final o in g.options) {
        if (o.quantity > 0) {
          selectedVariations.add({
            'variation_id': o.id,
            'quantity': o.quantity,
            'variation_name': o.name,
            'price_adjustment': o.priceDelta,
            'calories': o.calories.round(),
            'protein': o.protein.round(),
            'carbs': o.carbs.round(),
            'fat': o.fat.round(),
          });
        }
      }
    }

    setState(() => _adding = true);

    try {
      final addToCart = ref.read(addToCartProvider);

      await addToCart(
        productId: widget.productId,
        quantity: cartQty,
        productName: productName,
        productDescription: productDescription,
        basePrice: basePrice,
        calories: baseCalories,
        protein: baseProtein,
        carbs: baseCarbs,
        fat: baseFat,
        perItemFinalPrice: perItemFinalPrice,
        instructions: instructions.isEmpty ? null : instructions,
        selectedVariations: selectedVariations,
        mergeIfSameConfig: true,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add to cart.\n$e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItem = widget.item;
    final row = _productRow;

    final title = ((row?['name'] ?? menuItem.name) ?? '').toString();
    final subtitle = ((row?['subtitle'] ?? menuItem.subtitle) ?? '').toString();
    final description = ((row?['description'] ?? '') ?? '').toString();

    final totals = _computeTotals();

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
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
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
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    snap: false,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 0,
                    collapsedHeight: 150,
                    expandedHeight: 150,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _PinnedProductCard(
                        item: menuItem,
                        title: title,
                        subtitle: subtitle,
                        description: description,
                        totals: totals,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      // You may tweak 180 if the bottom bar height changes
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                onDec: (opt) => _dec(g, opt),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // =========================================================
              // Bottom totals bar (flush to bottom)
              // =========================================================
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      0,
                    ), // no bottom gap
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 14,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ─── price pills row ───
                          Row(
                            children: [
                              Expanded(
                                child: _CompactPricePill(
                                  label: 'Base',
                                  value: _money(totals.basePrice),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CompactPricePill(
                                  label: 'Add-ons',
                                  value: totals.addonsPrice == 0
                                      ? _money(0)
                                      : '+ ${_money(totals.addonsPrice)}',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CompactPricePill(
                                  label: 'Per Item',
                                  value: _money(totals.finalPrice),
                                  bold: true,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ─── qty + total + add button ───
                          Row(
                            children: [
                              _QtyChipStepper(
                                qty: _cartQty,
                                onDec: (_loading || _adding || _cartQty <= 1)
                                    ? null
                                    : _decCartQty,
                                onInc: (_loading || _adding)
                                    ? null
                                    : _incCartQty,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _money(totals.finalPrice * _cartQty),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: (_loading || _adding)
                                      ? null
                                      : () => _addToCart(totals),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  child: _adding
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          children: const [
                                            Icon(
                                              Icons.add_shopping_cart,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

// =========================================================
// UI widgets
// =========================================================

class _PinnedProductCard extends StatelessWidget {
  const _PinnedProductCard({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.totals,
  });

  final MenuCardItem item;
  final String title;
  final String subtitle;
  final String description;
  final _Totals totals;

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtMacro(double v, {String suffix = ''}) {
    if (v.abs() < 0.00001) return '0$suffix';
    return '${v.round()}$suffix';
  }

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
                      'assets/logos/freshBlendzLogo.png',
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    'assets/logos/freshBlendzLogo.png',
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
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
                _HorizontalPills(
                  children: [
                    _ChipPill(text: 'Price ${_money(totals.finalPrice)}'),
                    _ChipPill(
                      text: 'Calories ${_fmtMacro(totals.finalCalories)}',
                    ),
                    _ChipPill(
                      text:
                          'Protein ${_fmtMacro(totals.finalProtein, suffix: "g")}',
                    ),
                    _ChipPill(
                      text:
                          'Carbs ${_fmtMacro(totals.finalCarbs, suffix: "g")}',
                    ),
                    _ChipPill(
                      text: 'Fat ${_fmtMacro(totals.finalFat, suffix: "g")}',
                    ),
                    if (totals.selected.isNotEmpty) ...[
                      const _PillDivider(),
                      ...totals.selected.map((s) {
                        final qtyPart = s.qty > 1 ? ' x${s.qty}' : '';
                        return _ChipPill(text: '${s.name}$qtyPart');
                      }),
                    ],
                  ],
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _HorizontalPills extends StatelessWidget {
  const _HorizontalPills({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

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
          fontSize: 12,
        ),
      ),
    );
  }
}

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
                child: InkWell(
                  onTap: () => onToggle(opt),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (opt.priceDelta != 0)
                                    _MiniPill(
                                      text:
                                          '${opt.priceDelta >= 0 ? '+' : ''}${opt.priceDelta.toStringAsFixed(2)}',
                                    ),
                                  if (opt.calories.abs() > 0.00001)
                                    _MiniPill(
                                      text: 'Calories ${opt.calories.round()}',
                                    ),
                                  if (opt.protein.abs() > 0.00001)
                                    _MiniPill(
                                      text: 'Protein ${opt.protein.round()}g',
                                    ),
                                  if (opt.carbs.abs() > 0.00001)
                                    _MiniPill(
                                      text: 'Carbs ${opt.carbs.round()}g',
                                    ),
                                  if (opt.fat.abs() > 0.00001)
                                    _MiniPill(text: 'Fat ${opt.fat.round()}g'),
                                ],
                              ),
                              if (opt.description?.trim().isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 8),
                                Text(
                                  opt.description!.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        group.max == 1
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
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // hint reflects per-option max
  static String _selectionHint({required int min, required int max}) {
    final minText = (min > 0) ? 'Choose at least $min' : 'Optional';
    final maxText = (max > 0) ? ' • Each up to $max' : '';
    return '$minText$maxText';
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }
}

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

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _CompactPricePill extends StatelessWidget {
  const _CompactPricePill({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              fontSize: bold ? 15 : 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyChipStepper extends StatelessWidget {
  const _QtyChipStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
  });

  final int qty;
  final VoidCallback? onDec;
  final VoidCallback? onInc;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDec,
            icon: const Icon(Icons.remove_circle_outline),
            splashRadius: 18,
          ),
          Text(
            '$qty',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          IconButton(
            onPressed: onInc,
            icon: const Icon(Icons.add_circle_outline),
            splashRadius: 18,
          ),
        ],
      ),
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

  // PER OPTION max qty (except max==1 radio)
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

  // group-level MIN selection (sum of option quantities)
  final int min;

  // per-option max quantity (except max==1 means radio group)
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
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.description,
  });

  final int id;
  final String name;
  final String? description;

  final double priceDelta;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  final bool isDefault;
  int quantity;
}

class _SelectedOpt {
  _SelectedOpt({
    required this.name,
    required this.qty,
    required this.priceDelta,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final int qty;
  final double priceDelta;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class _Totals {
  _Totals({
    required this.basePrice,
    required this.addonsPrice,
    required this.finalPrice,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.addonsCalories,
    required this.addonsProtein,
    required this.addonsCarbs,
    required this.addonsFat,
    required this.finalCalories,
    required this.finalProtein,
    required this.finalCarbs,
    required this.finalFat,
    required this.selected,
  });

  final double basePrice;
  final double addonsPrice;
  final double finalPrice;

  final double baseCalories;
  final double baseProtein;
  final double baseCarbs;
  final double baseFat;

  final double addonsCalories;
  final double addonsProtein;
  final double addonsCarbs;
  final double addonsFat;

  final double finalCalories;
  final double finalProtein;
  final double finalCarbs;
  final double finalFat;

  final List<_SelectedOpt> selected;
}
