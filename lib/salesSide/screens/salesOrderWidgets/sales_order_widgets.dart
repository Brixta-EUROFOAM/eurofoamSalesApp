// lib/salesSide/screens/salesOrderWidgets/sales_order_widgets.dart

import 'package:flutter/material.dart';

class SoSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SoSectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 18, color: Colors.black87),
          if (icon != null) const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class SoInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final bool readOnly;
  final TextInputType keyboardType;
  final int maxLines;

  const SoInputField({
    super.key,
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: requiredField
              ? (v) => (v == null || v.isEmpty) ? "Required" : null
              : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class SoNumberField extends SoInputField {
  const SoNumberField({
    super.key,
    required super.controller,
    required super.label,
    super.requiredField = false,
  }) : super(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        );
}

class SoDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool requiredField;

  const SoDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          validator:
              requiredField ? (v) => v == null ? "Required" : null : null,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

