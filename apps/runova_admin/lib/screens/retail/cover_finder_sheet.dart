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
                    primary: 'AI Cover Compatibility Engine',
                    secondary: 'কভার সামঞ্জস্য ও শেয়ার্ড স্টক যাচাই',
                    primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
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
                if (hasSearched && searchResults.isEmpty)
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
