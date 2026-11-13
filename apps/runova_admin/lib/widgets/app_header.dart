import 'package:flutter/material.dart';
import '../data/auth/auth_service.dart';
import '../data/local/app_database.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Top App Header displaying actual Shop Name.
class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  void initState() {
    super.initState();
    _checkShopName();
  }

  @override
  void reassemble() {
    super.reassemble();
    _checkShopName();
  }

  Future<void> _checkShopName() async {
    try {
      final active = AuthService.instance.activeShopName;
      if (active.isEmpty || active == 'Runova Shop' || active == 'Runova') {
        final primary = await AppDatabase.instance.getPrimaryShop();
        if (primary != null && primary.name.isNotEmpty && mounted) {
          AuthService.instance.refreshShop(primary);
        }
      }
    } catch (_) {
      // Graceful fallback if databaseFactory not initialized in test environments
    }
  }

  /// If shop name is long, adjusts with the first 2 words.
  String _formatShopName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'Runova Shop' || trimmed == 'Runova') {
      return 'Runova';
    }
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length > 2) {
      return '${words[0]} ${words[1]}';
    }
    return trimmed;
  }

  void _showEditShopDialog(BuildContext context) {
    final current = AuthService.instance.activeShopName;
    final initialText = (current == 'Runova' || current == 'Runova Shop') ? '' : current;
    final ctrl = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Shop Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your shop name in English:',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                hintText: 'e.g. Runa Mobile',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await AuthService.instance.updateShopName(newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final rawShopName = AuthService.instance.activeShopName;
        final shopName = _formatShopName(rawShopName);
        final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : 'R';

        return Container(
          color: AppColors.surface.withValues(alpha: 0.95),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo & Shop Name (tappable to edit)
                  InkWell(
                    onTap: () => _showEditShopDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            shopName,
                            style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 14, color: AppColors.outline),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, size: 22),
                            color: AppColors.onSurfaceVariant,
                            onPressed: widget.onNotificationsTap,
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: widget.onProfileTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryContainer, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
