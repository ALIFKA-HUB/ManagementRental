import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/features/armada/viewmodels/driver_viewmodel.dart';
import 'driver_form_page.dart';

class DriverListView extends StatelessWidget {
  const DriverListView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DriverViewModel>();

    if (vm.isLoading && vm.drivers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.drivers.isEmpty) {
      return const AppEmptyState(
        title: 'Belum ada supir',
        subtitle: 'Tambah supir baru dengan tombol +',
        icon: Icons.person_outlined,
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.drivers.length,
          separatorBuilder: (_, _a) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = vm.drivers[i];
            return _DriverCard(driver: d);
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_driver_fab',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Supir'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverFormPage()),
            ).then((_) => vm.loadDrivers()),
          ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DriverViewModel>();
    final isOnTrip = driver.status == DriverStatus.onTrip;

    return Dismissible(
      key: Key(driver.driverId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Supir?'),
            content: Text('${driver.name} akan dihapus dari sistem.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final ok = await vm.deleteDriver(driver.driverId);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(vm.errorMessage ?? 'Gagal hapus'), backgroundColor: AppColors.error),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DriverFormPage(driver: driver)),
          ).then((_) => vm.loadDrivers()),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar inisial
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('ID: ${driver.codeId}  ·  ${driver.phone}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOnTrip ? AppColors.warning : AppColors.success).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    driver.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnTrip ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
