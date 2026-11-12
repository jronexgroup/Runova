import 'package:flutter/material.dart';
import '../../data/auth/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Owner Login Controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Shop Registration Controllers
  final _regShopNameCtrl = TextEditingController();
  final _regBengaliNameCtrl = TextEditingController();
  final _regOwnerNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regAddressCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  // Worker PIN Login Controllers
  final _workerShopIdCtrl = TextEditingController();
  final _workerCodeCtrl = TextEditingController();
  final _workerPinCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regShopNameCtrl.dispose();
    _regBengaliNameCtrl.dispose();
    _regOwnerNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regAddressCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _workerShopIdCtrl.dispose();
    _workerCodeCtrl.dispose();
    _workerPinCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleOwnerLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError('Please enter both Email and Password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.loginAdmin(email: email, password: pass);
    } catch (e) {
      _showError('Sign In failed: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleShopRegistration() async {
    final shopName = _regShopNameCtrl.text.trim();
    final ownerName = _regOwnerNameCtrl.text.trim();
    final phone = _regPhoneCtrl.text.trim();
    final address = _regAddressCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();

    if (shopName.isEmpty || ownerName.isEmpty || email.isEmpty || pass.isEmpty) {
      _showError('Shop name, owner name, email, and password are required.');
      return;
    }

    if (pass.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.registerShopAndAdmin(
        email: email,
        password: pass,
        shopName: shopName,
        ownerName: ownerName,
        phone: phone,
        address: address,
        nameBengali: _regBengaliNameCtrl.text.trim(),
      );
    } catch (e) {
      _showError('Registration failed: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWorkerLogin() async {
    final shopId = _workerShopIdCtrl.text.trim();
    final workerCode = _workerCodeCtrl.text.trim();
    final pin = _workerPinCtrl.text.trim();

    if (shopId.isEmpty || workerCode.isEmpty || pin.isEmpty) {
      _showError('Please enter Shop ID, Worker Code, and 4-digit PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.loginWorker(
        shopId: shopId,
        workerCode: workerCode,
        pin: pin,
      );
    } catch (e) {
      _showError(e.toString().replaceAll('ArgumentError:', '').replaceAll('Exception:', ''));
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 48, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(height: 12),
                  const BilingualText(
                    primary: 'RUNOVA SHOP ECOSYSTEM',
                    secondary: 'রুনোভা দোকান ও মেরামত ব্যবস্থাপনা',
                    primaryStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    secondaryStyle: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: 24),

                  // Auth Card Container
                  Container(
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
                      children: [
                        // Tab Bar
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primaryContainer,
                            unselectedLabelColor: AppColors.outline,
                            indicatorColor: AppColors.primaryContainer,
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: 'Owner Sign In'),
                              Tab(text: 'Register Shop'),
                              Tab(text: 'Worker PIN'),
                            ],
                          ),
                        ),

                        // Error Banner
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: AppColors.errorContainer,
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

                        // Tab Views
                        SizedBox(
                          height: 440,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOwnerLoginForm(),
                              _buildShopRegistrationForm(),
                              _buildWorkerLoginForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppColors.outline),
                      const SizedBox(width: 6),
                      Text(
                        'Offline-First Local SQLite Persistence Active',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sign in with Owner credentials', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Text('মালিকের অ্যাকাউন্টে লগইন করুন', style: TextStyle(color: AppColors.outline, fontSize: 12)),
          const SizedBox(height: 20),
          TextField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _loginPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _handleOwnerLogin,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign In as Owner • প্রবেশ করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildShopRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create New Shop & Owner Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Text('আপনার নতুন দোকান ও অ্যাকাউন্ট নিবন্ধন করুন', style: TextStyle(color: AppColors.outline, fontSize: 12)),
          const SizedBox(height: 14),
          TextField(
            controller: _regShopNameCtrl,
            decoration: const InputDecoration(labelText: 'Shop Name (e.g. Runova Telecom)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regBengaliNameCtrl,
            decoration: const InputDecoration(labelText: 'Bengali / Regional Name (দোকানের নাম)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regOwnerNameCtrl,
            decoration: const InputDecoration(labelText: 'Owner Full Name (মালিকের নাম)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number (ফোন নম্বর)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regAddressCtrl,
            decoration: const InputDecoration(labelText: 'Shop Address (ঠিকানা)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (min 6 characters)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _handleShopRegistration,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Register Shop • দোকান নিবন্ধন করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Technician Fast Counter PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Text('মেরামত কর্মীর কাউন্টার পিন লগইন', style: TextStyle(color: AppColors.outline, fontSize: 12)),
          const SizedBox(height: 20),
          TextField(
            controller: _workerShopIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Shop ID (e.g. SHOP-100293)',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _workerCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Worker Identifier (e.g. WORKER-1)',
              prefixIcon: Icon(Icons.person_pin_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _workerPinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '4 to 6-digit PIN',
              prefixIcon: Icon(Icons.pin_outlined, size: 20),
              counterText: '',
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _handleWorkerLogin,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Open Technician Bench • প্রবেশ করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
