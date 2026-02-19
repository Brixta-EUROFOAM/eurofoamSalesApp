// lib/screens/dvrwidgets/dvr_form_widgets.dart

import 'package:flutter/material.dart';

class _DvrStyle {
  static const Color cardNavy = Color(0xFF0F172A);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color inputFill = Color(0xFFF8FAFC);
}

class DvrFormSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const DvrFormSectionHeader({
    super.key,
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: _DvrStyle.cardNavy, size: 20),
          if (icon != null) const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _DvrStyle.textGrey,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class DvrInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final bool readOnly;
  final TextInputType keyboardType;
  final int maxLines;
  final Function(String)? onChanged;

  const DvrInputField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = true,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onChanged: onChanged,
          validator: isRequired
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? "$label is required" : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                readOnly ? Colors.grey.shade200 : _DvrStyle.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class DvrNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;

  const DvrNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return DvrInputField(
      controller: controller,
      label: label,
      isRequired: isRequired,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

class DvrDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isRequired;

  const DvrDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, isRequired: isRequired),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          validator:
              isRequired ? (v) => v == null ? "$label is required" : null : null,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: _DvrStyle.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items:
              items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class DvrMultiSelectField extends StatelessWidget {
  final String label;
  final List<String> items;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;

  const DvrMultiSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, isRequired: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            List<String> temp = List.from(selectedValues);

            final result = await showDialog<List<String>>(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: Text("Select $label"),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: items.map((item) {
                        final checked = temp.contains(item);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(item),
                          onChanged: (v) {
                            setState(() {
                              v == true
                                  ? temp.add(item)
                                  : temp.remove(item);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, temp),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              ),
            );

            if (result != null) onChanged(result);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _DvrStyle.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValues.isEmpty
                    ? Colors.grey.shade300
                    : _DvrStyle.accentGreen,
              ),
            ),
            child: selectedValues.isEmpty
                ? Text("Select $label",
                    style: const TextStyle(color: _DvrStyle.textGrey))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedValues
                        .map((e) => Chip(
                              label: Text(e),
                              backgroundColor: const Color(0xFFE6F4EA),
                            ))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class DvrLocationFetchWidget extends StatelessWidget {
  final TextEditingController lat;
  final TextEditingController lng;
  final VoidCallback onFetch;
  final bool isLoading;

  const DvrLocationFetchWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.onFetch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : onFetch,
          icon: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text("FETCH LOCATION"),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DvrInputField(
                controller: lat,
                label: "Latitude",
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DvrInputField(
                controller: lng,
                label: "Longitude",
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _Label({required this.label, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: _DvrStyle.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
