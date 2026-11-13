import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';
import 'add_inventory_screen.dart';
import 'cover_finder_sheet.dart';

class RetailScreen extends StatefulWidget {
  const RetailScreen({super.key});

  @override
  State<RetailScreen> createState() => _RetailScreenState();
}

class _RetailScreenState extends State<RetailScreen> {
  String selectedCategory = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectProduct(Product product) {
    setState(() {
      selectedProduct = product;
      selectedCover = null;
      saleQty = product.stockQuantity > 0 ? 1 : 0;
      activeSellPrice = product.defaultSellPrice;
    });
  }

  void _selectCover(CoverGroup cover) {
    setState(() {
      selectedCover = cover;
      selectedProduct = null;
      saleQty = cover.stockQuantity > 0 ? 1 : 0;
      activeSellPrice = cover.defaultSellPrice;
    });
  }

  Money get totalAmount => activeSellPrice * saleQty;

  Future<void> _executeSale() async {
    final state = ShopState.instance;

    if (selectedProduct != null) {
      final targetId = selectedProduct!.id;
      final qtySold = saleQty;
      final amount = totalAmount;
      final name = selectedProduct!.name;

      await state.recordRetailSale(
        product: selectedProduct!,
        quantity: qtySold,
        actualSellPrice: activeSellPrice,
        tenderType: tenderType,
      );

      final updated = state.products.firstWhere(
        (p) => p.id == targetId,
        orElse: () => selectedProduct!,
      );

      setState(() {
        selectedProduct = updated;
        saleQty = updated.stockQuantity > 0 ? 1 : 0;
        activeSellPrice = updated.defaultSellPrice;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tertiaryContainer,
            content: Text('Sale completed! Sold $qtySold x $name for ${amount.format()}'),
          ),
        );
      }
    } else if (selectedCover != null) {
      final targetId = selectedCover!.id;
      final qtySold = saleQty;
      final name = selectedCover!.baseName;

      await state.recordCoverSale(
        coverGroup: selectedCover!,
        actualSellPrice: activeSellPrice,
        tenderType: tenderType,
      );

      final updated = state.coverGroups.firstWhere(
        (c) => c.id == targetId,
        orElse: () => selectedCover!,
      );

      setState(() {
        selectedCover = updated;
        saleQty = updated.stockQuantity > 0 ? 1 : 0;
        activeSellPrice = updated.defaultSellPrice;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tertiaryContainer,
            content: Text('Cover sale completed! Sold $qtySold x $name'),
          ),
        );
      }
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
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddInventoryScreen(categoryType: InventoryCategoryType.accessory),
                      ),
                    );
                    if (mounted && ShopState.instance.products.isNotEmpty) {
                      _selectProduct(ShopState.instance.products.last);
                    }
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
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddInventoryScreen(categoryType: InventoryCategoryType.coverMatrix),
                            ),
                          );
                          if (mounted && ShopState.instance.coverGroups.isNotEmpty) {
                            _selectCover(ShopState.instance.coverGroups.last);
                          }
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
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddInventoryScreen(categoryType: InventoryCategoryType.temperedGlass),
                            ),
                          );
                          if (mounted && ShopState.instance.products.isNotEmpty) {
                            _selectProduct(ShopState.instance.products.last);
                          }
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
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddInventoryScreen(categoryType: InventoryCategoryType.repairPart),
                            ),
                          );
                          if (mounted && ShopState.instance.products.isNotEmpty) {
                            _selectProduct(ShopState.instance.products.last);
                          }
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
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddInventoryScreen(categoryType: InventoryCategoryType.smallItem),
                            ),
                          );
                          if (mounted && ShopState.instance.products.isNotEmpty) {
                            _selectProduct(ShopState.instance.products.last);
                          }
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

  void _showAdjustStockSheet(Product product) {
    int newStock = product.stockQuantity;
    final stockCtrl = TextEditingController(text: newStock.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${product.category} • Supplier: ${product.supplier}', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete Product',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteProduct(product);
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Adjust Stock Quantity (Pieces)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: newStock > 0
                        ? () => setSheetState(() {
                              newStock--;
                              stockCtrl.text = newStock.toString();
                            })
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: newStock > 0 ? AppColors.surfaceContainerHigh : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Icon(Icons.remove, size: 20, color: newStock > 0 ? AppColors.onSurface : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    height: 44,
                    child: TextField(
                      controller: stockCtrl,
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
                          setSheetState(() => newStock = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => setSheetState(() {
                      newStock++;
                      stockCtrl.text = newStock.toString();
                    }),
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
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [5, 10, 25].map((add) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('+$add', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () => setSheetState(() {
                              newStock += add;
                              stockCtrl.text = newStock.toString();
                            }),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ShopState.instance.updateProductStock(productId: product.id, newStock: newStock);
                    if (selectedProduct?.id == product.id) {
                      setState(() {
                        selectedProduct = product.copyWith(stockQuantity: newStock);
                        if (saleQty > newStock) saleQty = newStock > 0 ? 1 : 0;
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Update Stock', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjustCoverSheet(CoverGroup cover) {
    int newStock = cover.stockQuantity;
    final stockCtrl = TextEditingController(text: newStock.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cover.baseName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Shared Pool • Linked: ${cover.linkedModels.join(", ")}', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete Cover Matrix',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteCover(cover);
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Adjust Shared Stock Pool (Pieces)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: newStock > 0
                        ? () => setSheetState(() {
                              newStock--;
                              stockCtrl.text = newStock.toString();
                            })
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: newStock > 0 ? AppColors.surfaceContainerHigh : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Icon(Icons.remove, size: 20, color: newStock > 0 ? AppColors.onSurface : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    height: 44,
                    child: TextField(
                      controller: stockCtrl,
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
                          setSheetState(() => newStock = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => setSheetState(() {
                      newStock++;
                      stockCtrl.text = newStock.toString();
                    }),
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
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [5, 10, 25].map((add) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('+$add', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () => setSheetState(() {
                              newStock += add;
                              stockCtrl.text = newStock.toString();
                            }),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ShopState.instance.updateCoverStock(coverGroupId: cover.id, newStock: newStock);
                    if (selectedCover?.id == cover.id) {
                      setState(() {
                        selectedCover = cover.copyWith(stockQuantity: newStock);
                        if (saleQty > newStock) saleQty = newStock > 0 ? 1 : 0;
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Update Shared Stock', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}" from your store?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              await ShopState.instance.deleteProduct(product.id);
              if (selectedProduct?.id == product.id) {
                setState(() {
                  selectedProduct = null;
                  if (ShopState.instance.products.isNotEmpty) {
                    _selectProduct(ShopState.instance.products.first);
                  }
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCover(CoverGroup cover) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cover Matrix?'),
        content: Text('Are you sure you want to delete "${cover.baseName}" cover group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              await ShopState.instance.deleteCoverGroup(cover.id);
              if (selectedCover?.id == cover.id) {
                setState(() {
                  selectedCover = null;
                  if (ShopState.instance.coverGroups.isNotEmpty) {
                    _selectCover(ShopState.instance.coverGroups.first);
                  }
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCustomPriceDialog(Money currentPrice) {
    final priceCtrl = TextEditingController(text: currentPrice.inRupees.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Bargain Price (রফা মূল্য)'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Negotiated Unit Price (₹)',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(priceCtrl.text.trim());
              if (parsed != null && parsed >= 0) {
                setState(() => activeSellPrice = Money.fromRupees(parsed));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set Price'),
          ),
        ],
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
        final liveProduct = selectedProduct != null
            ? state.products.firstWhere((p) => p.id == selectedProduct!.id, orElse: () => selectedProduct!)
            : null;
        final liveCover = selectedCover != null
            ? state.coverGroups.firstWhere((c) => c.id == selectedCover!.id, orElse: () => selectedCover!)
            : null;

        final hasSelectedItem = liveProduct != null || liveCover != null;
        final currentStock = liveProduct != null
            ? liveProduct.stockQuantity
            : (liveCover != null ? liveCover.stockQuantity : 0);

        final itemName = liveProduct?.name ?? liveCover?.baseName ?? 'Select an item to begin sale';
        final basePrice = liveProduct?.defaultSellPrice ?? liveCover?.defaultSellPrice ?? Money.zero;

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
                      children: [
                        const Icon(Icons.search, size: 20, color: AppColors.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search inventory or scan...',
                              hintStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.clear, size: 18, color: AppColors.outline),
                          )
                        else
                          const Icon(Icons.qr_code_scanner, size: 20, color: AppColors.primary),
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
                          liveCover != null ? 'Mobile Cover (Shared Stock)' : 'Retail Accessory',
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
                    const SizedBox(height: 10),
                    const Text('Tap any product in your inventory below to load it into checkout.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ] else ...[
                    const SizedBox(height: 14),

                    // Quantity Stepper with 44x44 touch targets
                    Row(
                      children: [
                        const Text('Sale Quantity: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        _qtyBtn(
                          Icons.remove,
                          saleQty > 1 ? () => setState(() => saleQty--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$saleQty',
                            style: AppTypography.headlineSm.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _qtyBtn(
                          Icons.add,
                          saleQty < currentStock ? () => setState(() => saleQty++) : null,
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Bargaining Price Presets (Calculated from Base Price)
                    const Text('Price per Unit (Bargaining / রফা):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _bargainChip(
                            label: 'Full (₹${(basePrice.inRupees * 1.1).round()})',
                            price: Money.fromRupees((basePrice.inRupees * 1.1).round()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _bargainChip(
                            label: 'Fair (${basePrice.format()})',
                            price: basePrice,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _bargainChip(
                            label: 'Min (₹${(basePrice.inRupees * 0.9).round()})',
                            price: Money.fromRupees((basePrice.inRupees * 0.9).round()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.edit_note, size: 20),
                          tooltip: 'Custom Bargain Price',
                          onPressed: () => _showCustomPriceDialog(basePrice),
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
                          onPressed: currentStock > 0 && saleQty > 0 ? _executeSale : null,
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

            // 5. Dynamic Inventory List
            Builder(
              builder: (context) {
                final query = _searchCtrl.text.toLowerCase().trim();
                final List<Widget> inventoryTiles = [];

                // 1. Cover Groups (show when 'All' or 'Covers' is selected)
                if (selectedCategory == 'All' || selectedCategory == 'Covers') {
                  final filteredCovers = state.coverGroups.where((c) {
                    if (query.isEmpty) return true;
                    return c.matchesModel(query) || c.wholesaler.toLowerCase().contains(query);
                  }).toList();

                  for (final cover in filteredCovers) {
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
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.tune, color: AppColors.outline, size: 18),
                              tooltip: 'Adjust stock / delete',
                              onPressed: () => _showAdjustCoverSheet(cover),
                            ),
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
                  // Category match
                  bool catMatch = false;
                  if (selectedCategory == 'All') {
                    catMatch = true;
                  } else if (selectedCategory == 'Cables & Chargers') {
                    catMatch = p.category == 'Cables & Chargers' ||
                        p.category == 'General Accessories' ||
                        p.category == 'Accessories' ||
                        p.category == 'Audio & Earphones' ||
                        p.category == 'Smartwear & Gadgets' ||
                        p.category == 'Power Adapters';
                  } else if (selectedCategory == 'Tempered Glass') {
                    catMatch = p.category == 'Tempered Glass';
                  } else if (selectedCategory == 'Repair Parts') {
                    catMatch = p.category == 'Spare Parts';
                  } else if (selectedCategory == 'Small Items') {
                    catMatch = p.category == 'Small Items';
                  } else {
                    catMatch = p.category == selectedCategory;
                  }

                  if (!catMatch) return false;
                  if (query.isEmpty) return true;

                  return p.name.toLowerCase().contains(query) ||
                      p.category.toLowerCase().contains(query) ||
                      p.supplier.toLowerCase().contains(query) ||
                      (p.barcode != null && p.barcode!.toLowerCase().contains(query));
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
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.tune, color: AppColors.outline, size: 18),
                            tooltip: 'Adjust stock / delete',
                            onPressed: () => _showAdjustStockSheet(p),
                          ),
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
                        Text('No products found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceContainerHighest : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: onTap != null ? AppColors.outlineVariant : Colors.transparent),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColors.onSurface : Colors.grey.shade400,
        ),
      ),
    );
  }
}
