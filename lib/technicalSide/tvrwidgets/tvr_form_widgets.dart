// lib/technicalSide/widgets/tvr_form_widgets.dart
import 'package:flutter/material.dart';
import '../utils/tvr_constants.dart';

// ---------------------------------------------------------------------------
// 🟢 PUBLIC INPUT COMPONENTS
// ---------------------------------------------------------------------------

class TvrInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final Function(String)? onChanged;

  const TvrInputField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
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
          style: const TextStyle(
            color: TvrConstants.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : TvrConstants.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: TvrConstants.cardNavy,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TvrDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isRequired;

  const TvrDropdownField({
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
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: TvrConstants.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TvrConstants.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class TvrSwitchField extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const TvrSwitchField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: TvrConstants.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? TvrConstants.accentGreen.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TvrConstants.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TvrConstants.accentGreen,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🟢 SHARED UTILITY COMPONENTS (The ones you were missing)
// ---------------------------------------------------------------------------

class TvrSelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDone;

  const TvrSelectionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TvrConstants.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? TvrConstants.accentGreen : Colors.grey.shade300,
            width: isDone ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: TvrConstants.cardNavy),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDone ? TvrConstants.textDark : TvrConstants.textGrey,
                ),
              ),
            ),
            if (isDone)
              const Icon(Icons.check_circle, color: TvrConstants.accentGreen),
          ],
        ),
      ),
    );
  }
}

class TvrLocationFetchWidget extends StatelessWidget {
  final TextEditingController lat;
  final TextEditingController lng;
  final VoidCallback onFetch;
  final bool isLoading;

  const TvrLocationFetchWidget({
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onFetch,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text("FETCH LOCATION & ADDRESS"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: TvrConstants.cardNavy),
              foregroundColor: TvrConstants.cardNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TvrInputField(
                controller: lat,
                label: "Latitude",
                readOnly: true,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TvrInputField(
                controller: lng,
                label: "Longitude",
                readOnly: true,
                isRequired: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TvrSectionHeader extends StatelessWidget {
  final String title;
  const TvrSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: TvrConstants.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class TvrSearchTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const TvrSearchTile({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: TvrConstants.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? TvrConstants.accentGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: TvrConstants.cardNavy),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? value! : label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasValue
                      ? TvrConstants.textDark
                      : TvrConstants.textGrey,
                ),
              ),
            ),
            if (hasValue)
              const Icon(Icons.check_circle, color: TvrConstants.accentGreen),
          ],
        ),
      ),
    );
  }
}

class TvrMultiSelectField extends StatelessWidget {
  final String label;
  final List<String> items;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;
  final bool isRequired;

  const TvrMultiSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValues,
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
        InkWell(
          onTap: () async {
            final List<String>? result = await showDialog(
              context: context,
              builder: (ctx) {
                List<String> temp = List.from(selectedValues);
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        "Select $label",
                        style: const TextStyle(
                          color: TvrConstants.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: items.map((item) {
                            final checked = temp.contains(item);
                            return CheckboxListTile(
                              value: checked,
                              title: Text(item),
                              activeColor: TvrConstants.accentGreen,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    temp.add(item);
                                  } else {
                                    temp.remove(item);
                                  }
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TvrConstants.accentGreen,
                          ),
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (result != null) {
              onChanged(result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: TvrConstants.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValues.isEmpty
                    ? Colors.grey.shade300
                    : TvrConstants.accentGreen,
              ),
            ),
            child: selectedValues.isEmpty
                ? Text(
                    "Select $label",
                    style: TextStyle(color: TvrConstants.textGrey),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedValues
                        .map(
                          (e) => Chip(
                            label: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFE6F4EA),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 🟢 INTERNAL HELPERS
// ---------------------------------------------------------------------------

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
          color: TvrConstants.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          fontFamily: 'Roboto',
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