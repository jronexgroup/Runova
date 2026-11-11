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

  void _openAddProductDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'General Accessories');
    final supplierCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final sellPriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category *')),
              TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Wholesaler / Supplier *')),
              TextField(controller: buyPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy Price (₹) *', prefixText: '₹ ')),
              TextField(controller: sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Default Sell Price (₹) *', prefixText: '₹ ')),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock Quantity *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final cat = catCtrl.text.trim();
              final sup = supplierCtrl.text.trim();
              final buy = double.tryParse(buyPriceCtrl.text.trim()) ?? 0;
              final sell = double.tryParse(sellPriceCtrl.text.trim()) ?? 0;
              final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

              if (name.isNotEmpty && buy > 0 && sell > 0) {
                await ShopState.instance.addProduct(
                  name: name,
                  category: cat,
                  supplier: sup.isNotEmpty ? sup : 'Local Wholesaler',
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
            child: const Text('Save Product'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;
    final categories = ['All', 'Cables & Chargers', 'Covers', 'Tempered Glass', 'Small Items'];

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
                  onPressed: _openAddProductDialog,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (state.products.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.outline),
                    const SizedBox(height: 8),
                    const Text('No products in inventory yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    const Text('Tap "+ Add Product" above to stock your retail catalog.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              )
            else
              ...state.products.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
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
                  )),
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
