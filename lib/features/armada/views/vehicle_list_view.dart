import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/features/armada/viewmodels/vehicle_viewmodel.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'vehicle_form_page.dart';

class VehicleListView extends StatelessWidget {
  const VehicleListView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehicleViewModel>();
    final isAdmin = context.watch<AuthViewModel>().currentUser?.isAdmin ?? false;

    if (vm.isLoading && vm.vehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.vehicles.isEmpty) {
      return AppEmptyState(
        title: 'Belum ada kendaraan',
        subtitle: isAdmin ? 'Tambah kendaraan baru dengan tombol +' : null,
        icon: Icons.directions_car_outlined,
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.vehicles.length,
          separatorBuilder: (_, _a) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final v = vm.vehicles[i];
            return _VehicleCard(vehicle: v, isAdmin: isAdmin);
          },
        ),
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kendaraan'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormPage()),
              ).then((_) => vm.loadVehicles()),
            ),
          ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isAdmin;

  const _VehicleCard({required this.vehicle, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VehicleViewModel>();

    return Dismissible(
      key: Key(vehicle.vehicleId),
      direction: isAdmin ? DismissDirection.endToStart : DismissDirection.none,
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
            title: const Text('Hapus Kendaraan?'),
            content: Text('${vehicle.name} (${vehicle.plateNumber}) akan dihapus.'),
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
        final ok = await vm.deleteVehicle(vehicle.vehicleId);
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
          onTap: isAdmin
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VehicleFormPage(vehicle: vehicle)),
                  ).then((_) => vm.loadVehicles())
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _photoPlaceholder(),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(vehicle.plateNumber, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppChip(label: vehicle.category.label),
                          const SizedBox(width: 6),
                          AppChip(label: vehicle.status.label),
                        ],
                      ),
                      if (vehicle.conditionNotes != null && vehicle.conditionNotes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(vehicle.conditionNotes!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: Icon(
                      vehicle.status == VehicleStatus.ready ? Icons.build_outlined : Icons.check_circle_outline,
                      color: vehicle.status == VehicleStatus.ready ? AppColors.warning : AppColors.success,
                    ),
                    tooltip: vehicle.status == VehicleStatus.ready ? 'Set Bengkel' : 'Set Ready',
                    onPressed: () => vm.toggleStatus(vehicle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.directions_car, color: Colors.grey, size: 36),
      );
}
