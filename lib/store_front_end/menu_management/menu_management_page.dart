// Cheffery - menu_management_page.dart
//
// Menu management interface for store owners
// Allows adding, editing, and deleting menu items

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v0_0_0_cheffery_pos/core/global_providers/supabase_provider.dart';
import 'package:v0_0_0_cheffery_pos/core/themes/designs.dart';
import 'package:v0_0_0_cheffery_pos/store_front_end/menu_management/menu_management_data_source.dart';

class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({super.key});

  @override
  ConsumerState<MenuManagementPage> createState() =>
      _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage> {
  late MenuManagementDataSource _dataSource;
  bool _isLoading = true;
  String? _error;
  Map<String, List<Map<String, dynamic>>> _productsByCategory = {};
  List<Map<String, dynamic>> _allCategories = [];

  @override
  void initState() {
    super.initState();
    final supabase = ref.read(supabaseProvider);
    _dataSource = MenuManagementDataSource(supabase);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _dataSource.fetchProductsByCategory();
      final categories = await _dataSource.fetchCategories();

      if (!mounted) return;

      setState(() {
        _productsByCategory = products;
        _allCategories = categories;
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

  void _showProductDialog({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        dataSource: _dataSource,
        allCategories: _allCategories,
        product: product,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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

    try {
      await _dataSource.deleteProduct(productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2329),
      appBar: AppBar(
        title: const Text(
          'Menu Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2A2D34),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.black87),
        label: const Text(
          'Add Item',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
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
                        Text(
                          'Error loading menu items',
                          style: const TextStyle(
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
              : _productsByCategory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.white38,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No menu items yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first item',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _productsByCategory.entries.map((entry) {
                        final categoryName = entry.key;
                        final products = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...products.map((product) {
                              return _ProductCard(
                                product: product,
                                onEdit: () => _showProductDialog(
                                  product: product,
                                ),
                                onDelete: () => _deleteProduct(
                                  product['product_id'] as int,
                                  product['name'] as String,
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    ),
    );
  }
}

// ===========================
// Product Card Widget
// ===========================
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final subtitle = product['subtitle'] as String? ?? '';
    final basePrice = product['base_price'] as num? ?? 0;
    final calories = product['calories'] as int?;

    return Card(
      color: const Color(0xFF2A2F37),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (calories != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          '$calories cal',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================
// Product Form Dialog
// ===========================
class _ProductFormDialog extends StatefulWidget {
  final MenuManagementDataSource dataSource;
  final List<Map<String, dynamic>> allCategories;
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;

  const _ProductFormDialog({
    required this.dataSource,
    required this.allCategories,
    this.product,
    required this.onSaved,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _imageUriController = TextEditingController();
  final _highlightedFeatureController = TextEditingController();

  int? _selectedCategoryId;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      _nameController.text = widget.product!['name'] as String? ?? '';
      _subtitleController.text = widget.product!['subtitle'] as String? ?? '';
      _descriptionController.text =
          widget.product!['description'] as String? ?? '';
      _priceController.text =
          (widget.product!['base_price'] as num?)?.toString() ?? '';
      _caloriesController.text =
          (widget.product!['calories'] as int?)?.toString() ?? '';
      _proteinController.text =
          (widget.product!['protein'] as int?)?.toString() ?? '';
      _carbsController.text =
          (widget.product!['carbs'] as int?)?.toString() ?? '';
      _fatController.text = (widget.product!['fat'] as int?)?.toString() ?? '';
      _imageUriController.text = widget.product!['image_uri'] as String? ?? '';
      _highlightedFeatureController.text =
          widget.product!['highlighted_feature'] as String? ?? '';
      _selectedCategoryId = widget.product!['category_id'] as int?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _imageUriController.dispose();
    _highlightedFeatureController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() => _error = 'Please select a category');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final price = double.parse(_priceController.text.trim());
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

      if (widget.product == null) {
        await widget.dataSource.createProduct(
          categoryId: _selectedCategoryId!,
          name: _nameController.text.trim(),
          subtitle: _subtitleController.text.trim(),
          description: _descriptionController.text.trim(),
          basePrice: price,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          imageUri: _imageUriController.text.trim().isEmpty
              ? null
              : _imageUriController.text.trim(),
          highlightedFeature:
              _highlightedFeatureController.text.trim().isEmpty
                  ? null
                  : _highlightedFeatureController.text.trim(),
        );
      } else {
        await widget.dataSource.updateProduct(
          productId: widget.product!['product_id'] as int,
          categoryId: _selectedCategoryId!,
          name: _nameController.text.trim(),
          subtitle: _subtitleController.text.trim(),
          description: _descriptionController.text.trim(),
          basePrice: price,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          imageUri: _imageUriController.text.trim().isEmpty
              ? null
              : _imageUriController.text.trim(),
          highlightedFeature:
              _highlightedFeatureController.text.trim().isEmpty
                  ? null
                  : _highlightedFeatureController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'Product created successfully'
                : 'Product updated successfully',
          ),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    widget.product == null ? 'Add Menu Item' : 'Edit Menu Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: _inputDecoration('Select category'),
                        dropdownColor: const Color(0xFF2A2F37),
                        style: const TextStyle(color: Colors.white),
                        items: widget.allCategories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'] as int,
                            child: Text(cat['category_name'] as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                        },
                        validator: (val) =>
                            val == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Name', _nameController, required: true),
                      const SizedBox(height: 16),
                      _buildTextField('Subtitle', _subtitleController),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Description',
                        _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Base Price',
                        _priceController,
                        required: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        prefixText: '\$',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nutritional Information (Optional)',
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
                      _buildTextField(
                        'Highlighted Feature',
                        _highlightedFeatureController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Image Path (e.g., acai-bowl.jpg)',
                        _imageUriController,
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
                        : Text(
                            widget.product == null ? 'Create' : 'Save',
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label,
            prefixText: prefixText,
          ),
          validator: required
              ? (val) => val?.trim().isEmpty ?? true ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: const Color(0xFF1F2329),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    );
  }
}
