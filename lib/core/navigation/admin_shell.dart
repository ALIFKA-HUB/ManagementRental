import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentalin/features/armada/views/armada_page.dart';
import 'package:rentalin/features/booking/views/booking_page.dart';
import 'package:rentalin/features/dashboard/views/dashboard_page.dart';
import 'package:rentalin/features/schedule/views/schedule_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  DateTime? _lastBackPress;

  void _goToArmada() => setState(() => _selectedIndex = 3);

  List<Widget> get _pages => [
    DashboardPage(onGoToArmada: _goToArmada),
    const SchedulePage(),
    const BookingPage(),
    const ArmadaPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tekan sekali lagi untuk keluar')),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jadwal'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Booking'),
            NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Armada'),
          ],
        ),
      ),
    );
  }
}
