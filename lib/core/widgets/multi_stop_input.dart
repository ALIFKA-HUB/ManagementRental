import 'package:flutter/material.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_input.dart';

class MultiStopInput extends StatefulWidget {
  final List<String> initialRoutes;
  final ValueChanged<List<String>> onChanged;

  const MultiStopInput({
    super.key,
    required this.initialRoutes,
    required this.onChanged,
  });

  @override
  State<MultiStopInput> createState() => _MultiStopInputState();
}

class _MultiStopInputState extends State<MultiStopInput> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRoutes.isEmpty ? [''] : widget.initialRoutes;
    _controllers = initial.map((r) => TextEditingController(text: r)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notifyParent() {
    widget.onChanged(_controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList());
  }

  void _addStop() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeStop(int index) {
    if (_controllers.length <= 1) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rute Perjalanan', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ...List.generate(_controllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Stop ${i + 1}',
                    hint: i == 0 ? 'Titik keberangkatan' : 'Tujuan/transit',
                    controller: _controllers[i],
                    onChanged: (_) => _notifyParent(),
                  ),
                ),
                if (_controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: AppColors.error),
                    onPressed: () => _removeStop(i),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Tambah Rute'),
          onPressed: _addStop,
        ),
      ],
    );
  }
}
