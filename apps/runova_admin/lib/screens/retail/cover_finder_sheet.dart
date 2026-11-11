import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

/// AI Cover Compatibility Finder bottom sheet (from retail prototype).
class CoverFinderSheet extends StatefulWidget {
  final Function(CoverGroup coverGroup) onSelectCover;

  const CoverFinderSheet({super.key, required this.onSelectCover});

  @override
  State<CoverFinderSheet> createState() => _CoverFinderSheetState();
}

class _CoverFinderSheetState extends State<CoverFinderSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CoverGroup> searchResults = [];
  bool hasSearched = false;

  void _search(String query) {
    final state = ShopState.instance;
    setState(() {
      hasSearched = query.trim().isNotEmpty;
      if (!hasSearched) {
        searchResults = [];
      } else {
        searchResults = state.coverGroups.where((c) => c.matchesModel(query)).toList();
      }
    });
  }

  void _openAddCoverDialog() {
    final baseCtrl = TextEditingController();
    final modelsCtrl = TextEditingController();
    final wholesalerCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final sellCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Cover Group (Shared Stock)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base Name (e.g. iPhone 13/14 MagSafe) *',
                ),
              ),
              TextField(
                controller: modelsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Linked Models (comma separated) *',
                  hintText: 'iPhone 13, iPhone 14',
                ),
              ),
              TextField(
                controller: wholesalerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Wholesaler *',
                ),
              ),
              TextField(
                controller: buyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Buy Price (₹) *', prefixText: '₹ '),
              ),
              TextField(
                controller: sellCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Default Sell Price (₹) *', prefixText: '₹ '),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Initial Shared Stock *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final base = baseCtrl.text.trim();
              final models = modelsCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final wholesaler = wholesalerCtrl.text.trim();
              final buy = double.tryParse(buyCtrl.text.trim()) ?? 0;
              final sell = double.tryParse(sellCtrl.text.trim()) ?? 0;
              final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

              if (base.isNotEmpty && models.isNotEmpty && buy > 0 && sell > 0) {
                await ShopState.instance.addCoverGroup(
                  baseName: base,
                  linkedModels: models,
                  wholesaler: wholesaler.isNotEmpty ? wholesaler : 'Local Wholesaler',
                  buyPrice: Money.fromRupees(buy),
                  defaultSellPrice: Money.fromRupees(sell),
                  initialStock: stock,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) _search(_searchController.text);
              }
            },
            child: const Text('Save Cover Group'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.onSecondaryContainer, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const BilingualText(
                    primary: 'Cover Compatibility Engine',
                    secondary: 'কভার সামঞ্জস্য ও শেয়ার্ড স্টক যাচাই',
                    primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primaryContainer),
                    tooltip: 'Add Cover Group',
                    onPressed: _openAddCoverDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Input
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search model (e.g. iPhone 13, Redmi Note 12)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 14),

          // Search Results or All Groups
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (state.coverGroups.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.phone_android, size: 36, color: AppColors.outline),
                        const SizedBox(height: 8),
                        const Text('No mobile cover groups registered yet', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Tap "+" at the top right to create your first cover group.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  )
                else if (hasSearched && searchResults.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.outline),
                          const SizedBox(height: 6),
                          Text('Not Found in Inventory', style: AppTypography.headlineSm),
                          const SizedBox(height: 2),
                          const Text(
                            'কোনো কভার রেকর্ড পাওয়া যায়নি',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...(hasSearched ? searchResults : state.coverGroups).map((group) {
                    final isOutOfStock = group.stockQuantity <= 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOutOfStock ? AppColors.error : AppColors.outlineVariant,
                          width: isOutOfStock ? 1 : 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  group.baseName,
                                  style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? AppColors.errorContainer
                                      : AppColors.tertiaryContainer.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOutOfStock ? 'Out of Stock — 0' : 'Available • ${group.stockQuantity} in stock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isOutOfStock ? AppColors.error : AppColors.tertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Linked Models: ${group.linkedModels.join(" • ")}',
                            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Price: ${group.defaultSellPrice.format()}',
                                style: AppTypography.labelMd.copyWith(color: AppColors.primaryContainer),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOutOfStock ? Colors.grey : AppColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: isOutOfStock
                                    ? null
                                    : () {
                                        widget.onSelectCover(group);
                                        Navigator.pop(context);
                                      },
                                child: const Text('Select for Sale', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
