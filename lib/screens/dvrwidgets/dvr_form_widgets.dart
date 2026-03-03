// lib/screens/dvrwidgets/dvr_form_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 ADDED FOR HAPTIC FEEDBACK
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS

class _DvrStyle {
  static const Color cardNavy = Color(0xFF0F172A);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  // static const Color accentGreen = Color(0xFF10B981);
  // static const Color inputFill = Color(0xFFF8FAFC);
}

class DvrFormSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const DvrFormSectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _DvrStyle.cardNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _DvrStyle.cardNavy, size: 20),
            ),
          if (icon != null) const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: _DvrStyle.textDark,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class DvrInputField extends StatefulWidget {
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
  State<DvrInputField> createState() => _DvrInputFieldState();
}

class _DvrInputFieldState extends State<DvrInputField> {
  // 🔥 Focus node to drive smart borders
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: widget.label, isRequired: widget.isRequired),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: _DvrStyle.cardNavy.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            style: const TextStyle(
              color: _DvrStyle.textDark,
              fontWeight: FontWeight.w600,
            ),
            validator: widget.isRequired
                ? (v) =>
                      (v == null || v.trim().isEmpty) ? "Required field" : null
                : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.readOnly ? Colors.grey.shade200 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _DvrStyle.cardNavy,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
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
  final Function(String)? onChanged;

  const DvrNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DvrInputField(
      controller: controller,
      label: label,
      isRequired: isRequired,
      onChanged: onChanged,
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
          icon: const Icon(
            Icons.expand_more_rounded,
            color: _DvrStyle.textGrey,
          ),
          validator: isRequired ? (v) => v == null ? "Required" : null : null,
          isExpanded: true,
          style: const TextStyle(
            color: _DvrStyle.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            HapticFeedback.selectionClick();
            onChanged(val);
          },
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
            HapticFeedback.lightImpact();
            List<String> temp = List.from(selectedValues);

            final result = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) => StatefulBuilder(
                builder: (context, setState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select $label",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _DvrStyle.cardNavy,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final checked = temp.contains(item);

                            return CheckboxListTile(
                                  value: checked,
                                  activeColor: _DvrStyle.cardNavy,
                                  checkColor: Colors.white,
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      fontWeight: checked
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: checked
                                          ? _DvrStyle.cardNavy
                                          : _DvrStyle.textDark,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      v == true
                                          ? temp.add(item)
                                          : temp.remove(item);
                                    });
                                  },
                                )
                                .animate()
                                .fadeIn(delay: (index * 20).ms)
                                .slideX(begin: 0.05);
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _DvrStyle.cardNavy,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => Navigator.pop(context, temp),
                          child: const Text(
                            "CONFIRM SELECTION",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (result != null) onChanged(result);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValues.isEmpty
                    ? Colors.grey.shade200
                    : _DvrStyle.cardNavy.withOpacity(0.3),
              ),
            ),
            child: selectedValues.isEmpty
                ? const Text(
                    "Tap to select...",
                    style: TextStyle(color: _DvrStyle.textGrey, fontSize: 15),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedValues
                        .map(
                          (e) =>
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _DvrStyle.cardNavy.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _DvrStyle.cardNavy.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _DvrStyle.cardNavy,
                                  ),
                                ),
                              ).animate().scaleXY(
                                begin: 0.8,
                                duration: 200.ms,
                                curve: Curves.easeOutBack,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onFetch();
                    },
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _DvrStyle.cardNavy,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 20),
              label: Text(
                isLoading ? "LOCATING SATELLITES..." : "FETCH EXACT LOCATION",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DvrStyle.cardNavy,
                side: BorderSide(
                  color: isLoading
                      ? Colors.transparent
                      : _DvrStyle.cardNavy.withOpacity(0.5),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isLoading
                    ? _DvrStyle.cardNavy.withOpacity(0.05)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
            .animate(target: isLoading ? 1 : 0)
            .shimmer(
              duration: 1.seconds,
              color: _DvrStyle.cardNavy.withOpacity(0.2),
            ),

        const SizedBox(height: 16),

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
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
