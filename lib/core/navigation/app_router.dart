import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/auth/views/login_page.dart';
import 'admin_shell.dart';
import 'operator_shell.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return StreamBuilder(
      stream: authVM.authStateChanges,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Logged in — load user model if not yet loaded
        if (authVM.currentUser == null) {
          authVM.loadCurrentUser(snapshot.data!.uid);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
