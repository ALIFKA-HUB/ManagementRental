import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/utils/connectivity_service.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  StreamSubscription<bool>? _sub;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    final service = context.read<ConnectivityService>();
    _wasOffline = !service.isOnline;

    _sub = service.connectionStream.listen((isOnline) {
      if (!mounted) return;
      if (isOnline && _wasOffline) {
        // Just came back online — show green snack
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Kembali online ✓'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: isOnline
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 16),
                    child: const SafeArea(
                      bottom: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Tidak ada koneksi internet',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
