import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.login(_emailCtrl.text, _passwordCtrl.text);
    if (!ok || !mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.directions_car, size: 44, color: Colors.black),
                ),
                const SizedBox(height: 20),

                Text('Rentalin', style: AppTypography.heading),
                const SizedBox(height: 6),
                Text(
                  'Manajemen armada & booking kendaraan',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondaryLight),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Email
                AppInput(
                  label: 'Email',
                  hint: 'admin@rentalin.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password
                AppInput(
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: !_passwordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                const SizedBox(height: 12),

                // Error message
                if (vm.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: AppTypography.caption.copyWith(color: AppColors.error),
                    ),
                  ),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Masuk',
                  onPressed: vm.isLoading ? null : _onLogin,
                  isLoading: vm.isLoading,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
