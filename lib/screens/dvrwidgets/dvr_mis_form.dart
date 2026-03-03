// lib/screens/dvrwidgets/dvr_mis_form.dart

import 'dart:async'; // 🔥 ADDED FOR DEBOUNCE
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS
import 'package:salesmanapp/technicalSide/utils/dvr_constants.dart';
import 'dvr_form_widgets.dart';

class DvrMisFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const DvrMisFormWidget({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<DvrMisFormWidget> createState() => _DvrMisFormWidgetState();
}

class _DvrMisFormWidgetState extends State<DvrMisFormWidget> {
  // -------------------------------
  // 🧠 STATES
  // -------------------------------
  String? _partyType;
  List<String> _brandSelling = [];

  // 🚀 O(1) CPU THROTTLING: Prevents parent widget tree rebuilds on every keystroke
  Timer? _debounce;

  // -------------------------------
  // 📝 CONTROLLERS
  // -------------------------------
  final TextEditingController _nameOfPartyCtrl = TextEditingController();
  final TextEditingController _feedbackCtrl = TextEditingController();
  final TextEditingController _solutionCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  // -------------------------------
  // 🔄 PUSH DATA TO PARENT
  // -------------------------------
  void _notifyParent() {
    widget.onDataChanged({
      'partyType': _partyType,
      'nameOfParty': _nameOfPartyCtrl.text,
      'brandSelling': _brandSelling,
      'feedbacks': _feedbackCtrl.text,
      'solutionBySalesperson': _solutionCtrl.text,
      'anyRemarks': _remarksCtrl.text,
      // Default zero for numeric fields required by DB schema
      'dealerTotalPotential': '0',
      'dealerBestPotential': '0',
      'todayOrderMt': '0',
      'todayCollectionRupees': '0',
      'visitType': 'MIS',
    });
  }

  // 🚀 BATTERY/CPU OPTIMIZATION: Debounce text input updates
  void _debouncedNotifyParent() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _notifyParent();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // 🚀 SPACE COMPLEXITY: Plug memory leaks
    _nameOfPartyCtrl.dispose();
    _feedbackCtrl.dispose();
    _solutionCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // 🧱 BUILD UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ----------------------------------
          /// 📊 MARKET INTELLIGENCE DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Market Intelligence (MIS)",
                icon: Icons.radar,
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrDropdownField(
                label: "MIS Type",
                value: _partyType,
                items: const [
                  'Competitor Analysis',
                  'Price Drop',
                  'New Scheme',
                  'Market Trend',
                  'Other',
                ],
                onChanged: (v) {
                  setState(() => _partyType = v);
                  _notifyParent(); // Instant update for dropdowns
                },
              )
              .animate()
              .fadeIn(delay: 50.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrInputField(
                controller: _nameOfPartyCtrl,
                label: "Competitor / Entity Name",
                isRequired: false,
                onChanged: (_) => _debouncedNotifyParent(), // 🔥 DEBOUNCED
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrMultiSelectField(
                label: "Brands Observed",
                items: DvrConstants.brandOptions,
                selectedValues: _brandSelling,
                onChanged: (vals) {
                  setState(() => _brandSelling = vals);
                  _notifyParent(); // Instant update for arrays
                },
              )
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          /// ----------------------------------
          /// 📝 FEEDBACKS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Observations & Feedback",
                icon: Icons.rate_review,
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrInputField(
                controller: _feedbackCtrl,
                label: "Detailed Market Observation",
                maxLines: 4,
                onChanged: (_) => _debouncedNotifyParent(), // 🔥 DEBOUNCED
              )
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrInputField(
                controller: _remarksCtrl,
                label: "Salesperson Remarks",
                maxLines: 2,
                isRequired: false,
                onChanged: (_) => _debouncedNotifyParent(), // 🔥 DEBOUNCED
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
