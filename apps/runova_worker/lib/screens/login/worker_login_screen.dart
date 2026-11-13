import 'package:flutter/material.dart';
import '../../data/auth/worker_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _shopIdCtrl = TextEditingController();
  final _workerCodeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _shopIdCtrl.dispose();
    _workerCodeCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final shopId = _shopIdCtrl.text.trim();
    final code = _workerCodeCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (shopId.isEmpty || code.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter Shop ID, Worker Code, and 4-digit PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await WorkerAuthService.instance.loginWithPin(
        shopId: shopId,
        workerCode: code,
        pin: pin,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('ArgumentError:', '').replaceAll('Exception:', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build_circle_rounded, size: 52, color: AppColors.secondaryContainer),
                  ),
                  const SizedBox(height: 14),
                  const BilingualText(
                    primary: 'RUNOVA TECHNICIAN BENCH',
                    secondary: 'মেরামত কর্মী কাউন্টার লগইন',
                    primaryStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    secondaryStyle: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        TextField(
                          controller: _shopIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Shop ID (e.g. SHOP-100293)',
                            prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _workerCodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Worker Code (e.g. WORKER-1, W-02)',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _pinCtrl,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '4 to 6-digit Counter PIN',
                            prefixIcon: Icon(Icons.pin_outlined, size: 20),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Open Technician Desk • প্রবেশ করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Offline-First Local SQLite Persistence Active',
                    style: AppTypography.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
