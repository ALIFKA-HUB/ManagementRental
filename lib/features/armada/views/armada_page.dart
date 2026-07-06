import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/armada/viewmodels/vehicle_viewmodel.dart';
import 'package:rentalin/features/armada/viewmodels/driver_viewmodel.dart';
import 'package:rentalin/features/armada/views/vehicle_form_page.dart';
import 'package:rentalin/features/armada/views/driver_form_page.dart';
import 'vehicle_list_view.dart';
import 'driver_list_view.dart';
import 'package:rentalin/core/navigation/app_page_route.dart';

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
              if (isAdmin)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final tabIndex = DefaultTabController.of(ctx).index;
                      if (tabIndex == 0) {
                        Navigator.push(
                          ctx,
                          AppPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: ctx.read<VehicleViewModel>(),
                              child: const VehicleFormPage(),
                            ),
                          ),
                        ).then((_) => ctx.read<VehicleViewModel>().loadVehicles());
                      } else {
                        Navigator.push(
                          ctx,
                          AppPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: ctx.read<DriverViewModel>(),
                              child: const DriverFormPage(),
                            ),
                          ),
                        ).then((_) => ctx.read<DriverViewModel>().loadDrivers());
                      }
                    },
                  ),
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
