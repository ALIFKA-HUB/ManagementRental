import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/armada/viewmodels/vehicle_viewmodel.dart';
import 'vehicle_list_view.dart';

class ArmadaPage extends StatelessWidget {
  const ArmadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isAdmin = authVM.currentUser?.isAdmin ?? false;

    return ChangeNotifierProvider(
      create: (_) => VehicleViewModel()..loadVehicles(),
      child: DefaultTabController(
        length: isAdmin ? 2 : 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Armada'),
            bottom: TabBar(
              tabs: [
                const Tab(text: 'Kendaraan'),
                if (isAdmin) const Tab(text: 'Supir'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              const VehicleListView(),
              if (isAdmin)
                const Center(child: Text('Supir — Phase 5')), // placeholder
            ],
          ),
        ),
      ),
    );
  }
}
