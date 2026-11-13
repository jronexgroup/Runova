import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';
import 'cover_finder_sheet.dart';

class RetailScreen extends StatefulWidget {
  const RetailScreen({super.key});

  @override
  State<RetailScreen> createState() => _RetailScreenState();
}

class _RetailScreenState extends State<RetailScreen> {
  String selectedCategory = 'All';

  // Selected Item for POS sale
  Product? selectedProduct;
  CoverGroup? selectedCover;

  int saleQty = 1;
  Money activeSellPrice = Money.zero;
  TenderType tenderType = TenderType.cash;

  @override
  void initState() {
    super.initState();
    final state = ShopState.instance;
    if (state.products.isNotEmpty) {
      _selectProduct(state.products.first);
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      selectedProduct = product;
      selectedCover = null;
      saleQty = 1;
      activeSellPrice = product.defaultSellPrice;
    });
  }

  void _selectCover(CoverGroup cover) {
    setState(() {
      selectedCover = cover;
      selectedProduct = null;
      saleQty = 1;
      activeSellPrice = cover.defaultSellPrice;
    });
  }

  Money get totalAmount => activeSellPrice * saleQty;

  void _executeSale() {
    final state = ShopState.instance;

    if (selectedProduct != null) {
      state.recordRetailSale(
        product: selectedProduct!,
        quantity: saleQty,
        actualSellPrice: activeSellPrice,
        tenderType: tenderType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tertiaryContainer,
          content: Text(
            'Sale completed! Sold $saleQty x ${selectedProduct!.name} for ${totalAmount.format()}',
          ),
        ),
      );
    } else if (selectedCover != null) {
      state.recordCoverSale(
        coverGroup: selectedCover!,
        actualSellPrice: activeSellPrice,
        tenderType: tenderType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tertiaryContainer,
          content: Text(
            'Cover sale completed! Stock reduced for ${selectedCover!.baseName}',
          ),
        ),
      );
    }
  }

  void _openCoverFinder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CoverFinderSheet(
        onSelectCover: _selectCover,
      ),
    );
  }

  // ==========================================
  // BENTO GRID POPUP & DEDICATED INTAKE DIALOGS
  // ==========================================

  void _openAddInventoryBento() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Clean, professional, no clunky instruction text)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: AppColors.primaryContainer, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Add Inventory Item',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'পণ্য বা আইটেম টাইপ নির্বাচন করুন',
                              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bento Tile 1: Mobile Accessories & Audio (Full Width Featured Card)
                _bentoCard(
                  title: 'Mobile Accessories & Audio',
                  subtitle: 'Chargers, Cables, Earphones, Smartwatches & Adapters',
                  bengaliTag: 'চার্জার, হেডফোন ও গ্যাজেট',
                  badgeText: 'SKU / Barcode',
                  icon: Icons.headphones_rounded,
                  cardColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  accentColor: const Color(0xFF1D4ED8),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAddAccessoryDialog();
                  },
                ),
                const SizedBox(height: 10),

                // Bento Row 1: Cover Matrix & Tempered Glass
                Row(
                  children: [
                    Expanded(
                      child: _bentoCard(
                        title: 'Cover Matrix',
                        subtitle: 'Shared pool stock across phone models',
                        bengaliTag: 'শেয়ার্ড ব্যাক কভার',
                        badgeText: 'Pool Stock',
                        icon: Icons.phone_android_rounded,
                        cardColor: const Color(0xFFFFFBEB),
                        borderColor: const Color(0xFFFDE68A),
                        accentColor: const Color(0xFFB45309),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openAddCoverDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _bentoCard(
                        title: 'Tempered Glass',
                        subtitle: '11D, Matte, Privacy, UV Glass',
                        bengaliTag: 'স্ক্রিন গার্ড',
                        badgeText: 'Screen Guard',
                        icon: Icons.shield_outlined,
                        cardColor: const Color(0xFFF0FDF4),
                        borderColor: const Color(0xFFBBF7D0),
                        accentColor: const Color(0xFF15803D),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openAddTemperedGlassDialog();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bento Row 2: Repair Spare Parts & Small Items
                Row(
                  children: [
                    Expanded(
                      child: _bentoCard(
                        title: 'Repair Parts',
                        subtitle: 'Displays, Batteries, CC Boards',
                        bengaliTag: 'মোবাইল পার্টস',
                        badgeText: 'Service Parts',
                        icon: Icons.build_circle_outlined,
                        cardColor: const Color(0xFFFFF1F2),
                        borderColor: const Color(0xFFFECDD3),
                        accentColor: const Color(0xFFBE123C),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openAddSparePartDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _bentoCard(
                        title: 'Small Items',
                        subtitle: 'OTG, SIM pins, pouch (₹1–₹20)',
                        bengaliTag: 'ছোট কাউন্টার আইটেম',
                        badgeText: '₹1–₹20 Items',
                        icon: Icons.widgets_outlined,
                        cardColor: const Color(0xFFFAF5FF),
                        borderColor: const Color(0xFFE9D5FF),
                        accentColor: const Color(0xFF7E22CE),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openAddSmallItemDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bentoCard({
    required String title,
    required String subtitle,
    required String bengaliTag,
    required String badgeText,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 2),
            Text(
              bengaliTag,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Supplier Dropdown with + New Option ---
  Widget _buildSupplierDropdown({
    required String selectedSupplier,
    required List<Supplier> suppliers,
    required TextEditingController newSupplierCtrl,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedSupplier,
          decoration: const InputDecoration(
            labelText: 'Wholesaler / Supplier *',
            prefixIcon: Icon(Icons.business_outlined, size: 20),
          ),
          items: [
            ...suppliers.map((s) => DropdownMenuItem(
                  value: s.name,
                  child: Text(s.name),
                )),
            const DropdownMenuItem(
              value: '__NEW__',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('+ New Supplier', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
          onChanged: onChanged,
        ),
        if (selectedSupplier == '__NEW__') ...[
          const SizedBox(height: 8),
          TextField(
            controller: newSupplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Enter New Supplier Name *',
              hintText: 'e.g. Royal Accessories Kolkata',
              prefixIcon: Icon(Icons.add_business, size: 18),
            ),
          ),
        ],
      ],
    );
  }

  Future<String> _resolveSupplier(String selectedSupplier, TextEditingController newSupplierCtrl) async {
    String sup = selectedSupplier == '__NEW__' ? newSupplierCtrl.text.trim() : selectedSupplier;
    if (selectedSupplier == '__NEW__' && sup.isNotEmpty) {
      await ShopState.instance.addSupplier(name: sup);
    }
    return sup.isEmpty ? 'Local Wholesaler' : sup;
  }

  // 1. DEDICATED DIALOG: MOBILE ACCESSORIES
  void _openAddAccessoryDialog() {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final sellPriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    final newSupplierCtrl = TextEditingController();

    String selectedCategory = 'Cables & Chargers';
    final existingSuppliers = ShopState.instance.suppliers;
    String selectedSupplier = existingSuppliers.isNotEmpty ? existingSuppliers.first.name : '__NEW__';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.headphones_rounded, color: Color(0xFF1D4ED8)),
              SizedBox(width: 8),
              Text('Add Accessory / Gadget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Boat Bassheads 100 / 33W Charger',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Sub-Category *'),
                  items: const [
                    DropdownMenuItem(value: 'Cables & Chargers', child: Text('Cables & Chargers')),
                    DropdownMenuItem(value: 'Audio & Earphones', child: Text('Audio & Earphones')),
                    DropdownMenuItem(value: 'Smartwear & Gadgets', child: Text('Smartwear & Gadgets')),
                    DropdownMenuItem(value: 'Power Adapters', child: Text('Power Adapters')),
                    DropdownMenuItem(value: 'Other Accessories', child: Text('Other Accessories')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 8),
                _buildSupplierDropdown(
                  selectedSupplier: selectedSupplier,
                  suppliers: existingSuppliers,
                  newSupplierCtrl: newSupplierCtrl,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSupplier = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: barcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / SKU (Optional)',
                    hintText: 'Scan or type barcode',
                    prefixIcon: Icon(Icons.qr_code_scanner, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Buy Price *', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sell Price *', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Quantity *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final buy = double.tryParse(buyPriceCtrl.text.trim()) ?? 0;
                final sell = double.tryParse(sellPriceCtrl.text.trim()) ?? 0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (name.isNotEmpty && buy > 0 && sell > 0) {
                  final sup = await _resolveSupplier(selectedSupplier, newSupplierCtrl);
                  await ShopState.instance.addProduct(
                    name: name,
                    category: selectedCategory,
                    supplier: sup,
                    buyPrice: Money.fromRupees(buy),
                    defaultSellPrice: Money.fromRupees(sell),
                    initialStock: stock,
                    barcode: barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : null,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ShopState.instance.products.isNotEmpty) {
                    _selectProduct(ShopState.instance.products.last);
                  }
                }
              },
              child: const Text('Save Accessory'),
            ),
          ],
        ),
      ),
    );
  }

  // 2. DEDICATED DIALOG: COVER MATRIX (SHARED POOL STOCK)
  void _openAddCoverDialog() {
    final baseNameCtrl = TextEditingController();
    final modelsCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final sellPriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '15');
    final newSupplierCtrl = TextEditingController();

    final existingSuppliers = ShopState.instance.suppliers;
    String selectedSupplier = existingSuppliers.isNotEmpty ? existingSuppliers.first.name : '__NEW__';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.phone_android_rounded, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text('Add Cover Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baseNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Base Model Family Name *',
                    hintText: 'e.g. Realme 9 4G / Realme 9 Pro',
                    helperText: 'One pooled stock for all matching models',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: modelsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Linked Models (Comma Separated) *',
                    hintText: 'e.g. Realme 9, Realme 9 Pro, Narzo 50',
                  ),
                ),
                const SizedBox(height: 8),
                _buildSupplierDropdown(
                  selectedSupplier: selectedSupplier,
                  suppliers: existingSuppliers,
                  newSupplierCtrl: newSupplierCtrl,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSupplier = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Buy Price *', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sell Price *', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Shared Stock Pool *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB45309), foregroundColor: Colors.white),
              onPressed: () async {
                final baseName = baseNameCtrl.text.trim();
                final buy = double.tryParse(buyPriceCtrl.text.trim()) ?? 0;
                final sell = double.tryParse(sellPriceCtrl.text.trim()) ?? 0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (baseName.isNotEmpty && buy > 0 && sell > 0) {
                  final sup = await _resolveSupplier(selectedSupplier, newSupplierCtrl);
                  final models = modelsCtrl.text
                      .split(',')
                      .map((m) => m.trim())
                      .where((m) => m.isNotEmpty)
                      .toList();
                  if (!models.contains(baseName)) models.insert(0, baseName);

                  await ShopState.instance.addCoverGroup(
                    baseName: baseName,
                    linkedModels: models,
                    wholesaler: sup,
                    buyPrice: Money.fromRupees(buy),
                    defaultSellPrice: Money.fromRupees(sell),
                    initialStock: stock,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ShopState.instance.coverGroups.isNotEmpty) {
                    _selectCover(ShopState.instance.coverGroups.last);
                  }
                }
              },
              child: const Text('Save Cover Matrix'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. DEDICATED DIALOG: TEMPERED GLASS & SCREEN PROTECTORS
  void _openAddTemperedGlassDialog() {
    final modelCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final sellPriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '20');
    final newSupplierCtrl = TextEditingController();

    String selectedGlassType = '11D Curved Black Edge';
    final existingSuppliers = ShopState.instance.suppliers;
    String selectedSupplier = existingSuppliers.isNotEmpty ? existingSuppliers.first.name : '__NEW__';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFF15803D)),
              SizedBox(width: 8),
              Text('Add Tempered Glass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Device / Model *',
                    hintText: 'e.g. Redmi Note 12 5G / Poco X5',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedGlassType,
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
                    if (val != null) setDialogState(() => selectedGlassType = val);
                  },
                ),
                const SizedBox(height: 8),
                _buildSupplierDropdown(
                  selectedSupplier: selectedSupplier,
                  suppliers: existingSuppliers,
                  newSupplierCtrl: newSupplierCtrl,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSupplier = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Buy Price/pc *', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sell Price/pc *', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lot / Stock Quantity (pcs) *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
              onPressed: () async {
                final model = modelCtrl.text.trim();
                final buy = double.tryParse(buyPriceCtrl.text.trim()) ?? 0;
                final sell = double.tryParse(sellPriceCtrl.text.trim()) ?? 0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (model.isNotEmpty && buy > 0 && sell > 0) {
                  final sup = await _resolveSupplier(selectedSupplier, newSupplierCtrl);
                  await ShopState.instance.addProduct(
                    name: '$model ($selectedGlassType)',
                    category: 'Tempered Glass',
                    supplier: sup,
                    buyPrice: Money.fromRupees(buy),
                    defaultSellPrice: Money.fromRupees(sell),
                    initialStock: stock,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ShopState.instance.products.isNotEmpty) {
                    _selectProduct(ShopState.instance.products.last);
                  }
                }
              },
              child: const Text('Save Glass'),
            ),
          ],
        ),
      ),
    );
  }

  // 4. DEDICATED DIALOG: REPAIR SPARE PARTS
  void _openAddSparePartDialog() {
    final modelCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final sellPriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '3');
    final newSupplierCtrl = TextEditingController();

    String selectedPartType = 'Display / Combo (OLED)';
    final existingSuppliers = ShopState.instance.suppliers;
    String selectedSupplier = existingSuppliers.isNotEmpty ? existingSuppliers.first.name : '__NEW__';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.build_circle_outlined, color: Color(0xFFBE123C)),
              SizedBox(width: 8),
              Text('Add Repair Spare Part', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Mobile Model *',
                    hintText: 'e.g. Samsung Galaxy M31 / Redmi 10',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPartType,
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
                    if (val != null) setDialogState(() => selectedPartType = val);
                  },
                ),
                const SizedBox(height: 8),
                _buildSupplierDropdown(
                  selectedSupplier: selectedSupplier,
                  suppliers: existingSuppliers,
                  newSupplierCtrl: newSupplierCtrl,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSupplier = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Part Cost *', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Billing Price *', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Quantity *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE123C), foregroundColor: Colors.white),
              onPressed: () async {
                final model = modelCtrl.text.trim();
                final buy = double.tryParse(buyPriceCtrl.text.trim()) ?? 0;
                final sell = double.tryParse(sellPriceCtrl.text.trim()) ?? 0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (model.isNotEmpty && buy > 0 && sell > 0) {
                  final sup = await _resolveSupplier(selectedSupplier, newSupplierCtrl);
                  await ShopState.instance.addProduct(
                    name: '$model $selectedPartType',
                    category: 'Spare Parts',
                    supplier: sup,
                    buyPrice: Money.fromRupees(buy),
                    defaultSellPrice: Money.fromRupees(sell),
                    initialStock: stock,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ShopState.instance.products.isNotEmpty) {
                    _selectProduct(ShopState.instance.products.last);
                  }
                }
              },
              child: const Text('Save Spare Part'),
            ),
          ],
        ),
      ),
    );
  }

  // 5. DEDICATED DIALOG: SMALL ITEMS (₹1–₹20)
  void _openAddSmallItemDialog() {
    final nameCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController(text: '2');
    final sellPriceCtrl = TextEditingController(text: '10');
    final stockCtrl = TextEditingController(text: '50');
    final newSupplierCtrl = TextEditingController();

    final existingSuppliers = ShopState.instance.suppliers;
    String selectedSupplier = existingSuppliers.isNotEmpty ? existingSuppliers.first.name : '__NEW__';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.widgets_outlined, color: Color(0xFF7E22CE)),
              SizedBox(width: 8),
              Text('Add Small Counter Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Type-C OTG Adapter / SIM Pin',
                  ),
                ),
                const SizedBox(height: 8),
                _buildSupplierDropdown(
                  selectedSupplier: selectedSupplier,
                  suppliers: existingSuppliers,
                  newSupplierCtrl: newSupplierCtrl,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSupplier = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Buy Price/pc *', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sell Price *', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Quick Sell Price Chips
                Row(
                  children: [5, 10, 20, 30, 50].map((amt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text('₹$amt', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        padding: EdgeInsets.zero,
                        onPressed: () => setDialogState(() => sellPriceCtrl.text = amt.toString()),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Quantity *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7E22CE), foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final buy = double.tryParse(buyPriceCtrl.text.trim()) ?? 0;
                final sell = double.tryParse(sellPriceCtrl.text.trim()) ?? 0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (name.isNotEmpty && buy >= 0 && sell > 0) {
                  final sup = await _resolveSupplier(selectedSupplier, newSupplierCtrl);
                  await ShopState.instance.addProduct(
                    name: name,
                    category: 'Small Items',
                    supplier: sup,
                    buyPrice: Money.fromRupees(buy),
                    defaultSellPrice: Money.fromRupees(sell),
                    initialStock: stock,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ShopState.instance.products.isNotEmpty) {
                    _selectProduct(ShopState.instance.products.last);
                  }
                }
              },
              child: const Text('Save Small Item'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;
    final categories = ['All', 'Cables & Chargers', 'Covers', 'Tempered Glass', 'Repair Parts', 'Small Items'];

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final hasSelectedItem = selectedProduct != null || selectedCover != null;
        final currentStock = selectedProduct != null
            ? selectedProduct!.stockQuantity
            : (selectedCover != null ? selectedCover!.stockQuantity : 0);

        final itemName = selectedProduct?.name ?? selectedCover?.baseName ?? 'Select an item to begin sale';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Category Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Search & AI Cover Finder Toggle Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, size: 20, color: AppColors.outline),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search inventory or scan...',
                            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                          ),
                        ),
                        Icon(Icons.qr_code_scanner, size: 20, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Cover Finder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  onPressed: _openCoverFinder,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Active Checkout Terminal Card (Tactile Bargaining & Tender)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.4), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C00288E),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedCover != null ? 'Mobile Cover (Shared Stock)' : 'Retail Accessory',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      if (hasSelectedItem)
                        Text(
                          'Stock: $currentStock Available',
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: currentStock > 0 ? AppColors.tertiaryContainer : AppColors.error,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    itemName,
                    style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
                  ),

                  if (!hasSelectedItem) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Select a product from the list below, or tap "+ Add Product" to stock new items.',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),

                    // Quantity Stepper
                    Row(
                      children: [
                        const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _qtyBtn(Icons.remove, () {
                          if (saleQty > 1) setState(() => saleQty--);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$saleQty',
                            style: AppTypography.headlineSm.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        _qtyBtn(Icons.add, () {
                          if (saleQty < currentStock) setState(() => saleQty++);
                        }),
                      ],
                    ),
                    const Divider(height: 24),

                    // Bargaining Price Presets
                    const Text('Price per Unit (Bargaining / রফা):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _bargainChip(
                            label: 'Full (₹${(activeSellPrice.inRupees * 1.1).round()})',
                            price: Money.fromRupees((activeSellPrice.inRupees * 1.1).round()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _bargainChip(
                            label: 'Fair (${activeSellPrice.format()})',
                            price: activeSellPrice,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _bargainChip(
                            label: 'Min (₹${(activeSellPrice.inRupees * 0.9).round()})',
                            price: Money.fromRupees((activeSellPrice.inRupees * 0.9).round()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tender selection
                    Row(
                      children: [
                        Expanded(
                          child: _tenderChip(TenderType.cash, Icons.payments),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tenderChip(TenderType.upi, Icons.qr_code_scanner),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total & Confirm Sale Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Collectible', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            Text(
                              totalAmount.format(),
                              style: AppTypography.displayNumericMobile.copyWith(
                                color: AppColors.primaryContainer,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStock > 0 ? AppColors.primaryContainer : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                          label: const Text('Confirm Sale', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: currentStock > 0 ? _executeSale : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Products List Header with Add Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BilingualText(
                  primary: 'Registered Inventory',
                  secondary: 'দোকানের নিবন্ধিত পণ্য তালিকা',
                  primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: _openAddInventoryBento,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Builder(
              builder: (context) {
                final List<Widget> inventoryTiles = [];

                // 1. Cover Groups (show when 'All' or 'Covers' is selected)
                if (selectedCategory == 'All' || selectedCategory == 'Covers') {
                  for (final cover in state.coverGroups) {
                    inventoryTiles.add(Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone_android_rounded, color: Color(0xFFB45309), size: 20),
                        ),
                        title: Text(cover.baseName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Cover Matrix • Linked: ${cover.linkedModels.join(", ")} • Stock: ${cover.stockQuantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cover.defaultSellPrice.format(),
                              style: AppTypography.labelLg.copyWith(color: AppColors.primaryContainer),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                              onPressed: () => _selectCover(cover),
                            ),
                          ],
                        ),
                      ),
                    ));
                  }
                }

                // 2. Retail Products
                final filteredProducts = state.products.where((p) {
                  if (selectedCategory == 'All') return true;
                  if (selectedCategory == 'Cables & Chargers') {
                    return p.category == 'Cables & Chargers' ||
                        p.category == 'General Accessories' ||
                        p.category == 'Accessories' ||
                        p.category == 'Audio & Earphones' ||
                        p.category == 'Smartwear & Gadgets' ||
                        p.category == 'Power Adapters';
                  }
                  if (selectedCategory == 'Tempered Glass') {
                    return p.category == 'Tempered Glass';
                  }
                  if (selectedCategory == 'Repair Parts') {
                    return p.category == 'Spare Parts';
                  }
                  if (selectedCategory == 'Small Items') {
                    return p.category == 'Small Items';
                  }
                  return p.category == selectedCategory;
                }).toList();

                for (final p in filteredProducts) {
                  inventoryTiles.add(Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          p.category == 'Tempered Glass'
                              ? Icons.shield_outlined
                              : (p.category == 'Spare Parts'
                                  ? Icons.build_circle_outlined
                                  : (p.category == 'Small Items' ? Icons.widgets_outlined : Icons.inventory_2_outlined)),
                          color: AppColors.primaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${p.category} • Supplier: ${p.supplier} • Stock: ${p.stockQuantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.defaultSellPrice.format(),
                            style: AppTypography.labelLg.copyWith(color: AppColors.primaryContainer),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                            onPressed: () => _selectProduct(p),
                          ),
                        ],
                      ),
                    ),
                  ));
                }

                if (inventoryTiles.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.outline),
                        SizedBox(height: 8),
                        Text('No products in this category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Tap "+ Add Product" above to stock your retail catalog.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return Column(children: inventoryTiles);
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _bargainChip({required String label, required Money price}) {
    final isSelected = activeSellPrice == price;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
        foregroundColor: isSelected ? Colors.white : AppColors.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => setState(() => activeSellPrice = price),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _tenderChip(TenderType type, IconData icon) {
    final isSelected = tenderType == type;
    return InkWell(
      onTap: () => setState(() => tenderType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.onSurface),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.onSurface),
      ),
    );
  }
}
