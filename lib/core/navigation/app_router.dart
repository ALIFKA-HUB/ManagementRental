import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/auth/views/login_page.dart';
import 'admin_shell.dart';
import 'operator_shell.dart';

import 'package:rentalin/features/splash/views/splash_page.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashPage();
    }

    final authVM = context.watch<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: authVM.authStateChanges,
      builder: (context, snapshot) {
        // Loading Auth State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Memuat sesi...');
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Logged in — load user model if not yet loaded
        if (authVM.currentUser == null) {
          authVM.loadCurrentUser(snapshot.data!.uid);
          return const _LoadingScreen(message: 'Menyiapkan data pengguna...');
        }

        // Route berdasarkan role
        if (authVM.currentUser!.isAdmin) {
          return const AdminShell();
        } else {
          return const OperatorShell();
        }
      },
    );
  }
}

class _LoadingScreen extends StatefulWidget {
  final String message;
  const _LoadingScreen({required this.message});

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen> {
  bool _isTimeout = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isTimeout = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isTimeout ? 'Waktu habis. Tidak ada koneksi internet atau server lambat.' : widget.message,
              style: TextStyle(
                color: _isTimeout ? Colors.red : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
