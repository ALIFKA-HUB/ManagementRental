import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/features/armada/viewmodels/vehicle_viewmodel.dart';
import 'package:rentalin/features/armada/views/vehicle_form_page.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';
import 'package:rentalin/core/navigation/app_page_route.dart';

class VehicleListView extends StatefulWidget {
  const VehicleListView({super.key});

  @override
  State<VehicleListView> createState() => _VehicleListViewState();
}

class _VehicleListViewState extends State<VehicleListView> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<VehicleViewModel>();
    _searchCtrl = TextEditingController(text: vm.searchQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehicleViewModel>();
    final isAdmin = context.watch<AuthViewModel>().currentUser?.isAdmin ?? false;

    if (_searchCtrl.text != vm.searchQuery) {
      _searchCtrl.text = vm.searchQuery;
    }

    if (vm.isLoading && vm.isOriginalListEmpty) {
      return const AppListSkeleton();
    }

    return Column(
      children: [
        // Pinned Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari nama atau plat nomor...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: vm.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => vm.setSearchQuery(''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            onChanged: vm.setSearchQuery,
          ),
        ),

        // Category Chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: vm.selectedCategory == null,
                onSelected: (selected) {
                  if (selected) vm.setSelectedCategory(null);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: vm.selectedCategory == null ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              ...VehicleCategory.values.map((cat) {
                final isSelected = vm.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      vm.setSelectedCategory(selected ? cat : null);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List Kendaraan
        Expanded(
          child: vm.vehicles.isEmpty
              ? (vm.searchQuery.isNotEmpty || vm.selectedCategory != null
                  ? const AppEmptyState(
                      title: 'Kendaraan tidak ditemukan',
                      icon: Icons.search_off_outlined,
                    )
                  : const AppEmptyState(
                      title: 'Belum ada kendaraan',
                      icon: Icons.directions_car_outlined,
                    ))
              : RefreshIndicator(
                  onRefresh: vm.loadVehicles,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: vm.vehicles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final v = vm.vehicles[i];
                      return _VehicleCard(vehicle: v, isAdmin: isAdmin);
                    },
                  ),
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
                    AppPageRoute(
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
                    onSelected: (val) async {
                      if (val == 'status') {
                        final ok = await vm.toggleStatus(vehicle);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(vm.errorMessage ?? 'Gagal mengubah status kendaraan.'), backgroundColor: AppColors.error),
                          );
                        }
                      } else if (val == 'edit') {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: vm,
                              child: VehicleFormPage(vehicle: vehicle),
                            ),
                          ),
                        );
                      } else if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Kendaraan'),
                            content: Text('Yakin ingin menghapus ${vehicle.name}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final ok = await vm.deleteVehicle(vehicle.vehicleId);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(vm.errorMessage ?? 'Gagal menghapus kendaraan.'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: vehicle.status != VehicleStatus.inUse,
                        child: const Text('Hapus'),
                      ),
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
