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

    Widget content;
    if (vm.vehicles.isEmpty) {
      content = AppEmptyState(
        title: 'Belum ada kendaraan',
        subtitle: isAdmin ? 'Tambah kendaraan baru dengan tombol +' : null,
        icon: Icons.directions_car_outlined,
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.vehicles.length,
        separatorBuilder: (_, _a) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final v = vm.vehicles[i];
          return _VehicleCard(vehicle: v, isAdmin: isAdmin);
        },
      );
    }

    return content;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAdmin
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: VehicleFormPage(vehicle: vehicle),
                      ),
                    ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'status') vm.toggleStatus(vehicle);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'status',
                        child: Text(vehicle.status == VehicleStatus.ready ? 'Set Bengkel' : 'Set Ready'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    final plate = vehicle.plateNumber.isNotEmpty ? vehicle.plateNumber : '???';
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceMutedLight, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        plate,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}
