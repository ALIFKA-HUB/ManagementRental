import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/armada/viewmodels/vehicle_viewmodel.dart';
import 'package:rentalin/features/armada/viewmodels/driver_viewmodel.dart';
import 'package:rentalin/features/armada/views/vehicle_form_page.dart';
import 'package:rentalin/features/armada/views/driver_form_page.dart';
import 'vehicle_list_view.dart';
import 'driver_list_view.dart';

class ArmadaPage extends StatelessWidget {
  const ArmadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthViewModel>().currentUser?.isAdmin ?? false;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleViewModel()..loadVehicles()),
        if (isAdmin)
          ChangeNotifierProvider(create: (_) => DriverViewModel()..loadDrivers()),
      ],
      child: DefaultTabController(
        length: isAdmin ? 2 : 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Armada'),
            actions: [
              Builder(
                builder: (ctx) {
                  if (!isAdmin) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.add),
                    tooltip: 'Tambah Data',
                    onSelected: (val) {
                      if (val == 'v') {
                        final vm = ctx.read<VehicleViewModel>();
                        Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(value: vm, child: const VehicleFormPage()),
                        )).then((_) => vm.loadVehicles());
                      } else if (val == 'd') {
                        final vm = ctx.read<DriverViewModel>();
                        Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(value: vm, child: const DriverFormPage()),
                        )).then((_) => vm.loadDrivers());
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'v', child: Text('Tambah Kendaraan')),
                      PopupMenuItem(value: 'd', child: Text('Tambah Supir')),
                    ],
                  );
                },
              ),
            ],
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
              if (isAdmin) const DriverListView(),
            ],
          ),
        ),
      ),
    );
  }
}
