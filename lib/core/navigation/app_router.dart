import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/auth/views/login_page.dart';
import 'admin_shell.dart';
import 'operator_shell.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: authVM.authStateChanges,
      builder: (context, snapshot) {
        // Loading Auth State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.white);
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Logged in — load user model if not yet loaded
        if (authVM.currentUser == null) {
          authVM.loadCurrentUser(snapshot.data!.uid);
          return const Scaffold(backgroundColor: Colors.white);
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
