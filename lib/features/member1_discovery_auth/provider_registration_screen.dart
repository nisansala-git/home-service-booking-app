import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'provider_verification_screen.dart';

/// Member 1 (IT23684980): Provider Registration Form (Variant A)
/// Requirements: FR001 (Verified accounts), FR002 (Reliable registration flow)
class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _areaController = TextEditingController();
  final _rateController = TextEditingController();

  String _selectedCategory = 'plumbing';
  bool _agreedToTerms = false;
  bool _idUploaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _areaController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _proceedToVerification() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the service terms and conditions.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderVerificationScreen(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          category: _selectedCategory,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          area: _areaController.text.trim(),
          startingPrice: double.tryParse(_rateController.text.trim()) ?? 1500.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Become a Service Provider'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register Your Trade',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Join hundreds of verified professionals getting direct home service jobs.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Full Name
              const Text('Full Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Kasun Wickramasinghe'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Mobile Phone Number
              const Text('Contact phone (private)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '07X XXX XXXX',
                  prefixIcon:
                      Icon(Icons.phone_android, color: AppColors.primary),
                ),
                validator: (v) => v == null || v.trim().length < 9
                    ? 'Please enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 16),

              // Email Address
              const Text('Email Address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'name@example.com',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 16),

              const Text('Password'),
              TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) => v == null || v.length < 8
                      ? 'Use at least 8 characters'
                      : null),
              const SizedBox(height: 16),
              const Text('Confirm password'),
              TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (v) => v != _passwordController.text
                      ? 'Passwords do not match'
                      : null),
              const SizedBox(height: 16),
              // Service Category Dropdown
              const Text('Primary Trade Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(),
                items: AppConstants.serviceCategories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'] as String,
                    child: Text(c['name'] as String),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Service Area
              const Text('Service Area / Coverage',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Colombo, Kandy, Gampaha'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please specify your area' : null,
              ),
              const SizedBox(height: 16),

              // Starting Rate
              const Text('Standard Inspection / Starting Rate (Rs.)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 1500'),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  return amount == null || !amount.isFinite || amount <= 0
                      ? 'Enter a positive amount'
                      : null;
                },
              ),
              const SizedBox(height: 16),

              // Upload ID / Certification
              const Text(
                  'National ID / Trade Certification (Optional for preview)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Document uploads are not connected yet. You can register without a document.')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _idUploaded
                        ? const Color(0xFFE8F5E9)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _idUploaded
                          ? AppColors.success
                          : AppColors.cardBorder,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _idUploaded ? Icons.check_circle : Icons.upload_file,
                        color:
                            _idUploaded ? AppColors.success : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Document upload coming soon',
                        style: TextStyle(
                          color: _idUploaded
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Terms & Conditions Checkbox
              CheckboxListTile(
                value: _agreedToTerms,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: const Text(
                  'I agree to the FixIt Home Code of Conduct and Verified Provider Terms.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _proceedToVerification,
                child: const Text('Continue to Verification'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
