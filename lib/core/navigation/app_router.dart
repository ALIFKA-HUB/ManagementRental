import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/auth/views/login_page.dart';
import 'admin_shell.dart';
import 'operator_shell.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    // Minimum delay to guarantee skeleton visibility and smooth transition
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const LoginSkeleton();
    }

    final authVM = context.watch<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: authVM.authStateChanges,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoginSkeleton();
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Logged in — load user model if not yet loaded
        if (authVM.currentUser == null) {
          authVM.loadCurrentUser(snapshot.data!.uid);
          return const LoginSkeleton();
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
