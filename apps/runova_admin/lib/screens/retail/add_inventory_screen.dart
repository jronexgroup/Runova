import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';

enum InventoryCategoryType {
  accessory,
  coverMatrix,
  temperedGlass,
  repairPart,
  smallItem,
}

class AddInventoryScreen extends StatefulWidget {
  final InventoryCategoryType categoryType;

  const AddInventoryScreen({
    super.key,
    required this.categoryType,
  });

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameCtrl = TextEditingController();
  final _secondaryCtrl = TextEditingController(); // linked models or sub-category
  final _barcodeCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  // State Values
  int _quantity = 10;
  String? _selectedSupplier;
  String _selectedSubCategory = 'Cables & Chargers';
  String _selectedGlassType = '11D Curved Black Edge';
  String _selectedPartType = 'Display / Combo (OLED)';
  String _selectedGrade = 'Original (Tested)';

  @override
  void initState() {
    super.initState();
    // Default quantities by category
    switch (widget.categoryType) {
      case InventoryCategoryType.accessory:
        _quantity = 10;
        break;
      case InventoryCategoryType.coverMatrix:
        _quantity = 15;
        break;
      case InventoryCategoryType.temperedGlass:
        _quantity = 25;
        _buyPriceCtrl.text = '25';
        _sellPriceCtrl.text = '69';
        break;
      case InventoryCategoryType.repairPart:
        _quantity = 3;
        break;
      case InventoryCategoryType.smallItem:
        _quantity = 50;
        _buyPriceCtrl.text = '2';
        _sellPriceCtrl.text = '10';
        break;
    }
    _qtyCtrl.text = _quantity.toString();

    // Default supplier
    final existingSuppliers = ShopState.instance.suppliers;
    if (existingSuppliers.isNotEmpty) {
      _selectedSupplier = existingSuppliers.first.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _secondaryCtrl.dispose();
    _barcodeCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String get _screenTitle {
    switch (widget.categoryType) {
      case InventoryCategoryType.accessory:
        return 'Add Mobile Accessory';
      case InventoryCategoryType.coverMatrix:
        return 'Add Cover Matrix';
      case InventoryCategoryType.temperedGlass:
        return 'Add Tempered Glass';
      case InventoryCategoryType.repairPart:
        return 'Add Repair Spare Part';
      case InventoryCategoryType.smallItem:
        return 'Add Small Counter Item';
    }
  }

  String get _screenSubtitleBengali {
    switch (widget.categoryType) {
      case InventoryCategoryType.accessory:
        return 'চার্জার, হেডফোন ও গ্যাজেট';
      case InventoryCategoryType.coverMatrix:
        return 'শেয়ার্ড ব্যাক কভার স্টক';
      case InventoryCategoryType.temperedGlass:
        return 'টেম্পার্ড ও স্ক্রিন গার্ড';
      case InventoryCategoryType.repairPart:
        return 'মোবাইল ডিসপ্লে, ব্যাটারি ও পার্টস';
      case InventoryCategoryType.smallItem:
        return 'কাউন্টার খুচরা সামগ্রী (₹১–₹২০)';
    }
  }

  IconData get _screenIcon {
    switch (widget.categoryType) {
      case InventoryCategoryType.accessory:
        return Icons.headphones_rounded;
      case InventoryCategoryType.coverMatrix:
        return Icons.phone_android_rounded;
      case InventoryCategoryType.temperedGlass:
        return Icons.shield_outlined;
      case InventoryCategoryType.repairPart:
        return Icons.build_circle_outlined;
      case InventoryCategoryType.smallItem:
        return Icons.widgets_outlined;
    }
  }

  Color get _accentColor {
    switch (widget.categoryType) {
      case InventoryCategoryType.accessory:
        return const Color(0xFF1D4ED8);
      case InventoryCategoryType.coverMatrix:
        return const Color(0xFFB45309);
      case InventoryCategoryType.temperedGlass:
        return const Color(0xFF15803D);
      case InventoryCategoryType.repairPart:
        return const Color(0xFFBE123C);
      case InventoryCategoryType.smallItem:
        return const Color(0xFF7E22CE);
    }
  }

  void _showAddNewSupplierDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.business_rounded, color: AppColors.primaryContainer),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Wholesaler / Supplier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Supplier Name *',
                hintText: 'e.g. Royal Accessories Kolkata',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'e.g. 9876543210',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ShopState.instance.addSupplier(
                  name: name,
                  phone: phone,
                );
                if (mounted) {
                  setState(() {
                    _selectedSupplier = name;
                  });
                }
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  void _showSupplierPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final suppliers = ShopState.instance.suppliers;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Wholesaler / Supplier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ New', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddNewSupplierDialog();
                      },
                    ),
                  ],
                ),
                const Divider(),
                if (suppliers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.business_outlined, size: 36, color: AppColors.outline),
                          const SizedBox(height: 8),
                          const Text('No suppliers saved yet', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Supplier'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showAddNewSupplierDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suppliers.length,
                      itemBuilder: (ctx, idx) {
                        final s = suppliers[idx];
                        final isSelected = s.name == _selectedSupplier;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : AppColors.outline,
                          ),
                          title: Text(s.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
                          subtitle: s.phone.isNotEmpty ? Text(s.phone) : null,
                          onTap: () {
                            setState(() => _selectedSupplier = s.name);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateQuantity(int newQty) {
    if (newQty < 0) newQty = 0;
    setState(() {
      _quantity = newQty;
      _qtyCtrl.text = newQty.toString();
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final buy = double.tryParse(_buyPriceCtrl.text.trim()) ?? 0;
    final sell = double.tryParse(_sellPriceCtrl.text.trim()) ?? 0;
    final sup = _selectedSupplier?.trim().isNotEmpty == true
        ? _selectedSupplier!.trim()
        : 'Local Wholesaler';

    final state = ShopState.instance;

    switch (widget.categoryType) {
      case InventoryCategoryType.accessory:
        final name = _nameCtrl.text.trim();
        await state.addProduct(
          name: name,
          category: _selectedSubCategory,
          supplier: sup,
          buyPrice: Money.fromRupees(buy),
          defaultSellPrice: Money.fromRupees(sell),
          initialStock: _quantity,
          barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
        );
        break;

      case InventoryCategoryType.coverMatrix:
        final baseName = _nameCtrl.text.trim();
        final models = _secondaryCtrl.text
            .split(',')
            .map((m) => m.trim())
            .where((m) => m.isNotEmpty)
            .toList();
        if (!models.contains(baseName)) models.insert(0, baseName);

        await state.addCoverGroup(
          baseName: baseName,
          linkedModels: models,
          wholesaler: sup,
          buyPrice: Money.fromRupees(buy),
          defaultSellPrice: Money.fromRupees(sell),
          initialStock: _quantity,
        );
        break;

      case InventoryCategoryType.temperedGlass:
        final model = _nameCtrl.text.trim();
        await state.addProduct(
          name: '$model ($_selectedGlassType)',
          category: 'Tempered Glass',
          supplier: sup,
          buyPrice: Money.fromRupees(buy),
          defaultSellPrice: Money.fromRupees(sell),
          initialStock: _quantity,
        );
        break;

      case InventoryCategoryType.repairPart:
        final model = _nameCtrl.text.trim();
        await state.addProduct(
          name: '$model $_selectedPartType ($_selectedGrade)',
          category: 'Spare Parts',
          supplier: sup,
          buyPrice: Money.fromRupees(buy),
          defaultSellPrice: Money.fromRupees(sell),
          initialStock: _quantity,
        );
        break;

      case InventoryCategoryType.smallItem:
        final name = _nameCtrl.text.trim();
        await state.addProduct(
          name: name,
          category: 'Small Items',
          supplier: sup,
          buyPrice: Money.fromRupees(buy),
          defaultSellPrice: Money.fromRupees(sell),
          initialStock: _quantity,
        );
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tertiaryContainer,
          content: Text('Successfully added $_quantity pieces to inventory!'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_screenTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
            Text(_screenSubtitleBengali, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal), overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: _accentColor.withValues(alpha: 0.15),
              child: Icon(_screenIcon, color: _accentColor, size: 20),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. SPECIFIC ITEM FIELDS CARD
            _buildCategoryFieldsCard(),
            const SizedBox(height: 14),

            // 2. WHOLESALER / SUPPLIER CARD (WITH DIRECT + NEW BUTTON)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Wholesaler / Supplier *',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('+ New Supplier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          onPressed: _showAddNewSupplierDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showSupplierPickerSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedSupplier?.isNotEmpty == true
                                    ? _selectedSupplier!
                                    : 'Select or add wholesaler / supplier...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedSupplier?.isNotEmpty == true ? FontWeight.w600 : FontWeight.normal,
                                  color: _selectedSupplier?.isNotEmpty == true ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. PRICING & PROFIT MARGIN CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing (₹)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _buyPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Buy Price (₹) *',
                              prefixText: '₹ ',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              if (double.tryParse(val.trim()) == null) return 'Invalid';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _sellPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sell Price (₹) *',
                              prefixText: '₹ ',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              if (double.tryParse(val.trim()) == null) return 'Invalid';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (widget.categoryType == InventoryCategoryType.smallItem) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [5, 10, 20, 30, 50].map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text('₹$amt', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                              onPressed: () => setState(() => _sellPriceCtrl.text = amt.toString()),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // Realtime Margin Preview
                    Builder(builder: (context) {
                      final buy = double.tryParse(_buyPriceCtrl.text.trim()) ?? 0;
                      final sell = double.tryParse(_sellPriceCtrl.text.trim()) ?? 0;
                      if (buy > 0 && sell > 0) {
                        final profit = sell - buy;
                        final marginPct = ((profit / sell) * 100).round();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: profit >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profit >= 0 ? 'Estimated Profit: ₹${profit.toStringAsFixed(0)} ($marginPct% margin)' : 'Selling at a loss: -₹${(-profit).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: profit >= 0 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. QUANTITY & PIECES STEPPER (ALLOWS DECREASE / INCREASE & CHIPS)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Initial Stock Quantity (Pieces) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Decrease Pieces Button
                        InkWell(
                          onTap: _quantity > 0 ? () => _updateQuantity(_quantity - 1) : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _quantity > 0 ? AppColors.surfaceContainerHigh : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: _quantity > 0 ? AppColors.onSurface : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Editable Number Box
                        SizedBox(
                          width: 80,
                          height: 44,
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null && parsed >= 0) {
                                setState(() => _quantity = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Increase Pieces Button
                        InkWell(
                          onTap: () => _updateQuantity(_quantity + 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primaryContainer),
                            ),
                            child: const Icon(Icons.add, color: AppColors.primaryContainer, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quick Stock Presets
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_quantity >= 5)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: const Text('-5', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.error)),
                                      backgroundColor: AppColors.surfaceContainerLowest,
                                      side: BorderSide(color: AppColors.outlineVariant),
                                      onPressed: () => _updateQuantity(_quantity - 5),
                                    ),
                                  ),
                                ...[5, 10, 25, 50].map((step) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text('+$step', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      backgroundColor: AppColors.surfaceContainerLowest,
                                      side: BorderSide(color: AppColors.outlineVariant),
                                      onPressed: () => _updateQuantity(_quantity + step),
                                    ),
                                  );
                                }),
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
            const SizedBox(height: 20),

            // 5. SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text('Save $_screenTitle', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                onPressed: _saveItem,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFieldsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Item Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 12),

            if (widget.categoryType == InventoryCategoryType.accessory) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Boat Bassheads 100 / 33W Fast Charger',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Product name is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubCategory,
                decoration: const InputDecoration(labelText: 'Sub-Category *'),
                items: const [
                  DropdownMenuItem(value: 'Cables & Chargers', child: Text('Cables & Chargers')),
                  DropdownMenuItem(value: 'Audio & Earphones', child: Text('Audio & Earphones')),
                  DropdownMenuItem(value: 'Smartwear & Gadgets', child: Text('Smartwear & Gadgets')),
                  DropdownMenuItem(value: 'Power Adapters', child: Text('Power Adapters')),
                  DropdownMenuItem(value: 'Other Accessories', child: Text('Other Accessories')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubCategory = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Barcode / SKU (Optional)',
                  hintText: 'Scan or enter barcode',
                  prefixIcon: Icon(Icons.qr_code_scanner, size: 18),
                ),
              ),
            ] else if (widget.categoryType == InventoryCategoryType.coverMatrix) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base Model Family Name *',
                  hintText: 'e.g. Realme 9 4G / Realme 9 Pro',
                  helperText: 'One pooled stock for all matching phone models',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Base model name is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _secondaryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Linked Models (Comma Separated) *',
                  hintText: 'e.g. Realme 9, Realme 9 Pro, Narzo 50 4G',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Linked models are required' : null,
              ),
            ] else if (widget.categoryType == InventoryCategoryType.temperedGlass) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Phone Model / Series *',
                  hintText: 'e.g. Redmi Note 12 5G / Poco X5',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Model is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedGlassType,
                decoration: const InputDecoration(labelText: 'Glass Protection Type *'),
                items: const [
                  DropdownMenuItem(value: '11D Curved Black Edge', child: Text('11D Curved Black Edge')),
                  DropdownMenuItem(value: 'Matte Gaming (Anti-Glare)', child: Text('Matte Gaming (Anti-Glare)')),
                  DropdownMenuItem(value: 'Privacy Spy Filter', child: Text('Privacy Spy Filter')),
                  DropdownMenuItem(value: 'UV Liquid Full Glue', child: Text('UV Liquid Full Glue')),
                  DropdownMenuItem(value: 'Super D HD Clear', child: Text('Super D HD Clear')),
                  DropdownMenuItem(value: 'Camera Lens Protector', child: Text('Camera Lens Protector')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGlassType = val);
                },
              ),
            ] else if (widget.categoryType == InventoryCategoryType.repairPart) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Mobile Model *',
                  hintText: 'e.g. Samsung Galaxy M31 / Redmi Note 10',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Mobile model is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedPartType,
                decoration: const InputDecoration(labelText: 'Component / Part Type *'),
                items: const [
                  DropdownMenuItem(value: 'Display / Combo (OLED)', child: Text('Display / Combo (OLED)')),
                  DropdownMenuItem(value: 'Display / Combo (INCELL)', child: Text('Display / Combo (INCELL)')),
                  DropdownMenuItem(value: 'Original Battery', child: Text('Original Battery')),
                  DropdownMenuItem(value: 'Compatible Battery', child: Text('Compatible Battery')),
                  DropdownMenuItem(value: 'Charging Sub-Board (CC)', child: Text('Charging Sub-Board (CC)')),
                  DropdownMenuItem(value: 'Speaker / Ringer', child: Text('Speaker / Ringer')),
                  DropdownMenuItem(value: 'Camera Glass Lens', child: Text('Camera Glass Lens')),
                  DropdownMenuItem(value: 'Flex Cable / Buttons', child: Text('Flex Cable / Buttons')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPartType = val);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedGrade,
                decoration: const InputDecoration(labelText: 'Quality Grade *'),
                items: const [
                  DropdownMenuItem(value: 'Original (Tested)', child: Text('Original (Tested)')),
                  DropdownMenuItem(value: 'First Copy / AAA', child: Text('First Copy / AAA')),
                  DropdownMenuItem(value: 'Compatible Grade', child: Text('Compatible Grade')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGrade = val);
                },
              ),
            ] else if (widget.categoryType == InventoryCategoryType.smallItem) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Type-C to USB OTG Adapter / SIM Pin',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Item name is required' : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
