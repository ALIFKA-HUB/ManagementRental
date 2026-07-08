import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/features/armada/viewmodels/driver_viewmodel.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';
import 'driver_form_page.dart';
import 'package:rentalin/core/navigation/app_page_route.dart';

class DriverListView extends StatefulWidget {
  const DriverListView({super.key});

  @override
  State<DriverListView> createState() => _DriverListViewState();
}

class _DriverListViewState extends State<DriverListView> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<DriverViewModel>();
    _searchCtrl = TextEditingController(text: vm.searchQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DriverViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final isAdmin = authVM.currentUser?.isAdmin ?? false;

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
              hintText: 'Cari nama, ID, atau nomor hp...',
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

        // List Supir
        Expanded(
          child: vm.drivers.isEmpty
              ? (vm.searchQuery.isNotEmpty
                  ? const AppEmptyState(
                      title: 'Supir tidak ditemukan',
                      icon: Icons.search_off_outlined,
                    )
                  : const AppEmptyState(
                      title: 'Belum ada supir',
                      icon: Icons.person_off_outlined,
                    ))
              : RefreshIndicator(
                  onRefresh: vm.loadDrivers,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: vm.drivers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final d = vm.drivers[i];
                      return _DriverCard(driver: d, isAdmin: isAdmin);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final bool isAdmin;
  const _DriverCard({required this.driver, required this.isAdmin});

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: DriverFormPage(driver: driver),
              ),
            ),
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
                      Text('ID: ${driver.codeId}  •  ${driver.phone}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    if (isAdmin)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) async {
                          if (val == 'edit') {
                            Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: vm,
                                  child: DriverFormPage(driver: driver),
                                ),
                              ),
                            ).then((_) => vm.loadDrivers());
                          } else if (val == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Supir'),
                                content: Text('Yakin ingin menghapus ${driver.name}?${isOnTrip ? '\n\nPERINGATAN: Supir ini masih memiliki booking aktif.' : ''}'),
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
                            if (confirm == true) {
                              final ok = await vm.deleteDriver(driver.driverId);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(vm.errorMessage ?? 'Gagal menghapus supir.'), backgroundColor: AppColors.error),
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
                            enabled: !isOnTrip,
                            child: const Text('Hapus'),
                          ),
                        ],
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
}
