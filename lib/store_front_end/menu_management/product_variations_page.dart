// Cheffery - product_variations_page.dart
//
// UI for managing product variations (addons, extras, sizes, etc.)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/menu_management/variations_data_source.dart';

class ProductVariationsPage extends ConsumerStatefulWidget {
  final int productId;
  final String productName;

  const ProductVariationsPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<ProductVariationsPage> createState() => _ProductVariationsPageState();
}

class _ProductVariationsPageState extends ConsumerState<ProductVariationsPage> {
  late VariationsDataSource _dataSource;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _assignedVariationGroups = [];
  List<Map<String, dynamic>> _availableVariationTypes = [];

  @override
  void initState() {
    super.initState();
    final supabase = ref.read(supabaseProvider);
    _dataSource = VariationsDataSource(supabase);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final groups = await _dataSource.fetchProductVariationGroups(widget.productId);
      final availableTypes = await _dataSource.fetchAvailableVariationTypes(widget.productId);

      if (!mounted) return;

      setState(() {
        _assignedVariationGroups = groups;
        _availableVariationTypes = availableTypes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddVariationGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVariationGroupDialog(
        availableTypes: _availableVariationTypes,
        productId: widget.productId,
        dataSource: _dataSource,
        onAdded: _loadData,
      ),
    );
  }

  void _showCreateVariationTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateVariationTypeDialog(
        dataSource: _dataSource,
        onCreated: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2329),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Variations',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              widget.productName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2A2D34),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              onPressed: _showCreateVariationTypeDialog,
              backgroundColor: const Color(0xFF2A2F37),
              heroTag: 'create_type',
              icon: const Icon(Icons.category, color: AppColors.accent),
              label: const Text(
                'Create Group',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              onPressed: _showAddVariationGroupDialog,
              backgroundColor: AppColors.accent,
              heroTag: 'add_group',
              icon: const Icon(Icons.add, color: Colors.black87),
              label: const Text(
                'Add Existing Group',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error loading variations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _assignedVariationGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.tune,
                            size: 64,
                            color: Colors.white38,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No variation groups yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add a variation group to get started',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _assignedVariationGroups.length,
                            itemBuilder: (context, index) {
                              final group = _assignedVariationGroups[index];
                              return _VariationGroupCard(
                                group: group,
                                onEdit: () {
                                  _showEditVariationTypeDialog(group);
                                },
                                onRemove: () async {
                                  await _removeVariationGroup(group);
                                },
                                onAddVariation: () {
                                  _showAddVariationDialog(group);
                                },
                                onEditVariation: (variation) {
                                  _showEditVariationDialog(group, variation);
                                },
                                onRemoveVariation: (variation) async {
                                  await _removeVariation(variation);
                                },
                              );
                            },
                          ),
                        ),
                        // Cleanup buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2D34),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Database Cleanup',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _deleteUnusedVariations,
                                      icon: const Icon(Icons.delete_sweep, size: 18),
                                      label: const Text('Delete Unused Variations'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                        side: const BorderSide(color: Colors.orange),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _deleteUnusedVariationTypes,
                                      icon: const Icon(Icons.delete_sweep, size: 18),
                                      label: const Text('Delete Unused Groups'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Future<void> _removeVariationGroup(Map<String, dynamic> group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2F37),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Remove Variation Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove "${group['name']}" from this product? All assigned variations will be removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _dataSource.removeVariationGroupFromProduct(
        productId: widget.productId,
        variationTypeId: group['variation_type_id'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variation group removed successfully')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove group: $e')),
      );
    }
  }

  Future<void> _removeVariation(Map<String, dynamic> variation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2F37),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Remove Variation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove "${variation['name']}" from this product?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _dataSource.removeVariationFromProduct(
        productId: widget.productId,
        variationId: variation['variation_id'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variation removed successfully')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove variation: $e')),
      );
    }
  }

  void _showEditVariationTypeDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => _EditVariationTypeDialog(
        variationTypeId: group['variation_type_id'],
        name: group['name'],
        description: group['description'],
        minSelection: group['min_selection'],
        maxSelection: group['max_selection'],
        dataSource: _dataSource,
        onSaved: _loadData,
      ),
    );
  }

  void _showAddVariationDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => _AddOrCreateVariationDialog(
        productId: widget.productId,
        variationTypeId: group['variation_type_id'],
        variationTypeName: group['name'],
        dataSource: _dataSource,
        onAdded: _loadData,
      ),
    );
  }

  void _showEditVariationDialog(
    Map<String, dynamic> group,
    Map<String, dynamic> variation,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EditVariationSettingsDialog(
        productId: widget.productId,
        variation: variation,
        dataSource: _dataSource,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _deleteUnusedVariations() async {
    // First, fetch unused variations to show count
    try {
      final unusedVariations = await _dataSource.fetchUnusedVariations();

      if (!mounted) return;

      if (unusedVariations.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2F37),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'No Unused Variations',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'All variations in the database are currently assigned to at least one product.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
        return;
      }

      // Show confirmation with list
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2F37),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Delete Unused Variations',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The following ${unusedVariations.length} variation(s) are not assigned to any product and will be permanently deleted:',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ...unusedVariations.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${v['name']} (${v['type_name']})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Perform deletion
      final count = await _dataSource.deleteUnusedVariations();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count unused variation(s)')),
      );

      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete variations: $e')),
      );
    }
  }

  Future<void> _deleteUnusedVariationTypes() async {
    // First, fetch unused variation types to show count
    try {
      final unusedTypes = await _dataSource.fetchUnusedVariationTypes();

      if (!mounted) return;

      if (unusedTypes.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2F37),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'No Unused Variation Groups',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'All variation groups in the database are currently assigned to at least one product.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
        return;
      }

      // Show confirmation with list
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2F37),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Delete Unused Variation Groups',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The following ${unusedTypes.length} variation group(s) are not assigned to any product and will be permanently deleted (including all their variations):',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ...unusedTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will also delete all variations belonging to these groups. This action cannot be undone.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Perform deletion
      final count = await _dataSource.deleteUnusedVariationTypes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count unused variation group(s)')),
      );

      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete variation groups: $e')),
      );
    }
  }
}

// ===========================
// Variation Group Card Widget
// ===========================
class _VariationGroupCard extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onAddVariation;
  final Function(Map<String, dynamic>) onEditVariation;
  final Function(Map<String, dynamic>) onRemoveVariation;

  const _VariationGroupCard({
    required this.group,
    required this.onEdit,
    required this.onRemove,
    required this.onAddVariation,
    required this.onEditVariation,
    required this.onRemoveVariation,
  });

  @override
  State<_VariationGroupCard> createState() => _VariationGroupCardState();
}

class _VariationGroupCardState extends State<_VariationGroupCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name'] as String;
    final description = widget.group['description'] as String? ?? '';
    final minSelection = widget.group['min_selection'] as int? ?? 0;
    final maxSelection = widget.group['max_selection'] as int? ?? 0;
    final variations = widget.group['variations'] as List<dynamic>? ?? [];

    return Card(
      color: const Color(0xFF2A2F37),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Min: $minSelection, Max: $maxSelection',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white60),
                    onPressed: widget.onEdit,
                    tooltip: 'Edit group settings',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onRemove,
                    tooltip: 'Remove group',
                  ),
                ],
              ),
            ),
          ),

          // Variations List
          if (_isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Variations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onAddVariation,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Variation'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (variations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No variations added yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ...variations.map((variation) {
                      return _VariationItem(
                        variation: variation,
                        onEdit: () => widget.onEditVariation(variation),
                        onRemove: () => widget.onRemoveVariation(variation),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================
// Variation Item Widget
// ===========================
class _VariationItem extends StatelessWidget {
  final Map<String, dynamic> variation;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _VariationItem({
    required this.variation,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = variation['name'] as String;
    final description = variation['description'] as String? ?? '';
    final priceAdjustment = variation['price_adjustment'] as num? ?? 0;
    final calories = variation['calories'] as int?;
    final protein = variation['protein'] as int?;
    final carbs = variation['carbs'] as int?;
    final fat = variation['fat'] as int?;
    final isDefault = variation['is_default'] as bool? ?? false;
    final defaultQuantity = variation['default_quantity'] as int? ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2329),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDefault
              ? AppColors.accent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white60, size: 18),
                onPressed: onEdit,
                tooltip: 'Edit variation',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 18),
                onPressed: onRemove,
                tooltip: 'Remove variation',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (priceAdjustment != 0)
                _InfoChip(
                  icon: Icons.attach_money,
                  label: priceAdjustment > 0
                      ? '+\$${priceAdjustment.toStringAsFixed(2)}'
                      : '-\$${(-priceAdjustment).toStringAsFixed(2)}',
                  color: priceAdjustment > 0 ? Colors.green : Colors.red,
                ),
              if (calories != null)
                _InfoChip(
                  icon: Icons.local_fire_department,
                  label: '$calories cal',
                  color: Colors.orange,
                ),
              if (protein != null)
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: '${protein}g protein',
                  color: Colors.blue,
                ),
              if (carbs != null)
                _InfoChip(
                  icon: Icons.grain,
                  label: '${carbs}g carbs',
                  color: Colors.amber,
                ),
              if (fat != null)
                _InfoChip(
                  icon: Icons.water_drop,
                  label: '${fat}g fat',
                  color: Colors.purple,
                ),
              if (defaultQuantity > 1)
                _InfoChip(
                  icon: Icons.numbers,
                  label: 'Qty: $defaultQuantity',
                  color: Colors.cyan,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================
// Info Chip Widget
// ===========================
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================
// Add Variation Group Dialog
// ===========================
class _AddVariationGroupDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableTypes;
  final int productId;
  final VariationsDataSource dataSource;
  final VoidCallback onAdded;

  const _AddVariationGroupDialog({
    required this.availableTypes,
    required this.productId,
    required this.dataSource,
    required this.onAdded,
  });

  @override
  State<_AddVariationGroupDialog> createState() =>
      _AddVariationGroupDialogState();
}

class _AddVariationGroupDialogState extends State<_AddVariationGroupDialog> {
  int? _selectedTypeId;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2F37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Add Variation Group',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a variation type to add:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (widget.availableTypes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No available variation types. Create one first.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            ...widget.availableTypes.map((type) {
              final typeId = type['variation_type_id'] as int;
              final name = type['name'] as String;
              final description = type['description'] as String? ?? '';

              return RadioListTile<int>(
                value: typeId,
                groupValue: _selectedTypeId,
                onChanged: (val) => setState(() => _selectedTypeId = val),
                title: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: description.isNotEmpty
                    ? Text(
                        description,
                        style: const TextStyle(color: Colors.white60),
                      )
                    : null,
                activeColor: AppColors.accent,
              );
            }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _selectedTypeId == null || _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  try {
                    await widget.dataSource.addVariationGroupToProduct(
                      productId: widget.productId,
                      variationTypeId: _selectedTypeId!,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    widget.onAdded();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Variation group added successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add group: $e')),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black87,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

// ===========================
// Create Variation Type Dialog
// ===========================
class _CreateVariationTypeDialog extends StatefulWidget {
  final VariationsDataSource dataSource;
  final VoidCallback onCreated;

  const _CreateVariationTypeDialog({
    required this.dataSource,
    required this.onCreated,
  });

  @override
  State<_CreateVariationTypeDialog> createState() =>
      _CreateVariationTypeDialogState();
}

class _CreateVariationTypeDialogState
    extends State<_CreateVariationTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minSelectionController = TextEditingController(text: '0');
  final _maxSelectionController = TextEditingController(text: '1');
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minSelectionController.dispose();
    _maxSelectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final minSelection = int.parse(_minSelectionController.text.trim());
      final maxSelection = int.parse(_maxSelectionController.text.trim());

      await widget.dataSource.createVariationType(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        minSelection: minSelection,
        maxSelection: maxSelection,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variation type created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2F37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Create Variation Type',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField('Name', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Description', _descriptionController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSelectionController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Min Selection',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1F2329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val?.trim().isEmpty ?? true) return 'Required';
                        final minVal = int.tryParse(val!.trim());
                        if (minVal == null) return 'Must be a number';
                        if (minVal < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSelectionController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Max Selection',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1F2329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val?.trim().isEmpty ?? true) return 'Required';
                        final maxVal = int.tryParse(val!.trim());
                        if (maxVal == null) return 'Must be a number';
                        if (maxVal < 0) return 'Must be >= 0';
                        final minVal = int.tryParse(_minSelectionController.text.trim());
                        if (minVal != null && maxVal < minVal) {
                          return 'Must be >= min selection';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Min: minimum required selections, Max: maximum allowed selections',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black87,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1F2329),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      validator: required
          ? (val) => val?.trim().isEmpty ?? true ? 'Required' : null
          : null,
    );
  }
}

// ===========================
// Edit Variation Type Dialog
// ===========================
class _EditVariationTypeDialog extends StatefulWidget {
  final int variationTypeId;
  final String name;
  final String? description;
  final int minSelection;
  final int maxSelection;
  final VariationsDataSource dataSource;
  final VoidCallback onSaved;

  const _EditVariationTypeDialog({
    required this.variationTypeId,
    required this.name,
    this.description,
    required this.minSelection,
    required this.maxSelection,
    required this.dataSource,
    required this.onSaved,
  });

  @override
  State<_EditVariationTypeDialog> createState() =>
      _EditVariationTypeDialogState();
}

class _EditVariationTypeDialogState extends State<_EditVariationTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minSelectionController;
  late final TextEditingController _maxSelectionController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController(text: widget.description ?? '');
    _minSelectionController = TextEditingController(text: widget.minSelection.toString());
    _maxSelectionController = TextEditingController(text: widget.maxSelection.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minSelectionController.dispose();
    _maxSelectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final minSelection = int.parse(_minSelectionController.text.trim());
      final maxSelection = int.parse(_maxSelectionController.text.trim());

      await widget.dataSource.updateVariationType(
        variationTypeId: widget.variationTypeId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        minSelection: minSelection,
        maxSelection: maxSelection,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variation type updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2F37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Edit Variation Type',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField('Name', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Description', _descriptionController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSelectionController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Min Selection',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1F2329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val?.trim().isEmpty ?? true) return 'Required';
                        final minVal = int.tryParse(val!.trim());
                        if (minVal == null) return 'Must be a number';
                        if (minVal < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSelectionController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Max Selection',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1F2329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val?.trim().isEmpty ?? true) return 'Required';
                        final maxVal = int.tryParse(val!.trim());
                        if (maxVal == null) return 'Must be a number';
                        if (maxVal < 0) return 'Must be >= 0';
                        final minVal = int.tryParse(_minSelectionController.text.trim());
                        if (minVal != null && maxVal < minVal) {
                          return 'Must be >= min selection';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black87,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1F2329),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      validator: required
          ? (val) => val?.trim().isEmpty ?? true ? 'Required' : null
          : null,
    );
  }
}

// ===========================
// Add or Create Variation Dialog
// ===========================
class _AddOrCreateVariationDialog extends StatefulWidget {
  final int productId;
  final int variationTypeId;
  final String variationTypeName;
  final VariationsDataSource dataSource;
  final VoidCallback onAdded;

  const _AddOrCreateVariationDialog({
    required this.productId,
    required this.variationTypeId,
    required this.variationTypeName,
    required this.dataSource,
    required this.onAdded,
  });

  @override
  State<_AddOrCreateVariationDialog> createState() =>
      _AddOrCreateVariationDialogState();
}

class _AddOrCreateVariationDialogState
    extends State<_AddOrCreateVariationDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableVariations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableVariations();
  }

  Future<void> _loadAvailableVariations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final available = await widget.dataSource.fetchAvailableVariations(
        productId: widget.productId,
        variationTypeId: widget.variationTypeId,
      );

      if (!mounted) return;

      setState(() {
        _availableVariations = available;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVariationDialog(
        productId: widget.productId,
        variationTypeId: widget.variationTypeId,
        variationTypeName: widget.variationTypeName,
        dataSource: widget.dataSource,
        onAdded: () {
          widget.onAdded();
          Navigator.pop(context); // Close the selection dialog
        },
      ),
    );
  }

  Future<void> _addExistingVariation(int variationId) async {
    try {
      await widget.dataSource.addVariationToProduct(
        productId: widget.productId,
        variationId: variationId,
        isDefault: false,
        defaultQuantity: 1,
        sortOrder: 0,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variation added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add variation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2F37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Variation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'To: ${widget.variationTypeName}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAvailableVariations,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_availableVariations.isNotEmpty) ...[
                        const Text(
                          'Add existing variations:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._availableVariations.map((variation) {
                          return Card(
                            color: const Color(0xFF1F2329),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                variation['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '\$${(variation['price_adjustment'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.accent),
                                onPressed: () => _addExistingVariation(
                                    variation['variation_id']),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                      ],
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _showCreateDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Variation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

// ===========================
// Add Variation Dialog
// ===========================
class _AddVariationDialog extends StatefulWidget {
  final int productId;
  final int variationTypeId;
  final String variationTypeName;
  final VariationsDataSource dataSource;
  final VoidCallback onAdded;

  const _AddVariationDialog({
    required this.productId,
    required this.variationTypeId,
    required this.variationTypeName,
    required this.dataSource,
    required this.onAdded,
  });

  @override
  State<_AddVariationDialog> createState() => _AddVariationDialogState();
}

class _AddVariationDialogState extends State<_AddVariationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _defaultQuantityController = TextEditingController(text: '1');

  bool _isDefault = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _defaultQuantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final priceAdjustment = double.parse(_priceController.text.trim());
      final calories = _caloriesController.text.trim().isEmpty
          ? null
          : int.parse(_caloriesController.text.trim());
      final protein = _proteinController.text.trim().isEmpty
          ? null
          : int.parse(_proteinController.text.trim());
      final carbs = _carbsController.text.trim().isEmpty
          ? null
          : int.parse(_carbsController.text.trim());
      final fat = _fatController.text.trim().isEmpty
          ? null
          : int.parse(_fatController.text.trim());
      final defaultQuantity = int.parse(_defaultQuantityController.text.trim());

      // First, create the variation
      final variationId = await widget.dataSource.createVariation(
        variationTypeId: widget.variationTypeId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priceAdjustment: priceAdjustment,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

      // Then, add it to the product
      await widget.dataSource.addVariationToProduct(
        productId: widget.productId,
        variationId: variationId,
        isDefault: _isDefault,
        defaultQuantity: defaultQuantity,
        sortOrder: 0,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variation added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2F37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Variation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: ${widget.variationTypeName}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style:
                                const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField('Name', _nameController, required: true),
                      const SizedBox(height: 16),
                      _buildTextField('Description', _descriptionController),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Price Adjustment',
                        _priceController,
                        required: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        prefixText: '\$',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nutritional Information',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Calories',
                              _caloriesController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              'Protein (g)',
                              _proteinController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Carbs (g)',
                              _carbsController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              'Fat (g)',
                              _fatController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _defaultQuantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Default Quantity',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1F2329),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.accent, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val?.trim().isEmpty ?? true) return 'Required';
                          final quantity = int.tryParse(val!.trim());
                          if (quantity == null) return 'Must be a number';
                          if (quantity < 1) return 'Must be >= 1';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _isDefault,
                        onChanged: (val) => setState(() => _isDefault = val!),
                        title: const Text(
                          'Set as default selection',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'This variation will be pre-selected for customers',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        activeColor: AppColors.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black87),
                            ),
                          )
                        : const Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF1F2329),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      validator: required
          ? (val) => val?.trim().isEmpty ?? true ? 'Required' : null
          : null,
    );
  }
}

// ===========================
// Edit Variation Settings Dialog
// ===========================
class _EditVariationSettingsDialog extends StatefulWidget {
  final int productId;
  final Map<String, dynamic> variation;
  final VariationsDataSource dataSource;
  final VoidCallback onSaved;

  const _EditVariationSettingsDialog({
    required this.productId,
    required this.variation,
    required this.dataSource,
    required this.onSaved,
  });

  @override
  State<_EditVariationSettingsDialog> createState() =>
      _EditVariationSettingsDialogState();
}

class _EditVariationSettingsDialogState
    extends State<_EditVariationSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _defaultQuantityController;
  late final TextEditingController _sortOrderController;
  late bool _isDefault;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _defaultQuantityController = TextEditingController(
      text: (widget.variation['default_quantity'] as int? ?? 1).toString(),
    );
    _sortOrderController = TextEditingController(
      text: (widget.variation['sort_order'] as int? ?? 0).toString(),
    );
    _isDefault = widget.variation['is_default'] as bool? ?? false;
  }

  @override
  void dispose() {
    _defaultQuantityController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final defaultQuantity = int.parse(_defaultQuantityController.text.trim());
      final sortOrder = int.parse(_sortOrderController.text.trim());

      await widget.dataSource.updateProductVariationSettings(
        productId: widget.productId,
        variationId: widget.variation['variation_id'],
        isDefault: _isDefault,
        defaultQuantity: defaultQuantity,
        sortOrder: sortOrder,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.variation['name'] as String;

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2F37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _defaultQuantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Default Quantity',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1F2329),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              validator: (val) {
                if (val?.trim().isEmpty ?? true) return 'Required';
                final quantity = int.tryParse(val!.trim());
                if (quantity == null) return 'Must be a number';
                if (quantity < 1) return 'Must be >= 1';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortOrderController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Sort Order',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1F2329),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              validator: (val) {
                if (val?.trim().isEmpty ?? true) return 'Required';
                final sortOrder = int.tryParse(val!.trim());
                if (sortOrder == null) return 'Must be a number';
                if (sortOrder < 0) return 'Must be >= 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val!),
              title: const Text(
                'Set as default',
                style: TextStyle(color: Colors.white),
              ),
              activeColor: AppColors.accent,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black87,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
