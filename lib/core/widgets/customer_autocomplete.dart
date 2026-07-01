import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rentalin/data/models/customer_model.dart';
import 'package:rentalin/data/repositories/customer_repository.dart';

class CustomerAutocomplete extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const CustomerAutocomplete({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  @override
  State<CustomerAutocomplete> createState() => _CustomerAutocompleteState();
}

class _CustomerAutocompleteState extends State<CustomerAutocomplete> {
  final CustomerRepository _repo = CustomerRepository();
  List<CustomerModel> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  void _onNameChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) {
      setState(() => _showSuggestions = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _repo.searchByName(value);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  void _onSelect(CustomerModel customer) {
    widget.nameController.text = customer.name;
    widget.phoneController.text = customer.phone;
    setState(() => _showSuggestions = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.nameController,
          onChanged: _onNameChanged,
          decoration: InputDecoration(
            labelText: 'Nama Penyewa',
            hintText: 'Ketik nama untuk pencarian',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
        if (_showSuggestions)
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _suggestions.map((c) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(c.name),
                subtitle: Text(c.phone),
                onTap: () => _onSelect(c),
              )).toList(),
            ),
          ),
      ],
    );
  }
}
