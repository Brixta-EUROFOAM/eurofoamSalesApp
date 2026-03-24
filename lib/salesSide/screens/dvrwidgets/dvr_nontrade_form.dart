// lib/salesSide/screens/dvr_widgets/dvr_nontrade_form.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/salesSide/screens/dvrwidgets/dvr_constants.dart';
import 'dvr_form_widgets.dart';

class DvrNonTradeFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const DvrNonTradeFormWidget({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<DvrNonTradeFormWidget> createState() => _DvrNonTradeFormWidgetState();
}

class _DvrNonTradeFormWidgetState extends State<DvrNonTradeFormWidget> {
  // -------------------------------
  // 🧠 STATES
  // -------------------------------
  String? _partyType;
  String? _visitType;
  List<String> _brandSelling = [];
  DateTime? _expectedActivationDate;

  // 🚀 O(1) CPU THROTTLING: Prevents parent widget tree rebuilds on every keystroke
  Timer? _debounce;

  // -------------------------------
  // 📝 CONTROLLERS
  // -------------------------------
  final TextEditingController _nameOfPartyCtrl = TextEditingController();
  final TextEditingController _contactPhoneCtrl = TextEditingController();
  final TextEditingController _totalPotentialCtrl = TextEditingController();
  final TextEditingController _bestPotentialCtrl = TextEditingController();
  final TextEditingController _feedbackCtrl = TextEditingController();

  // 🚀 CRITICAL FIX: Attach listeners universally so we never miss an update
  @override
  void initState() {
    super.initState();
    _nameOfPartyCtrl.addListener(_debouncedNotifyParent);
    _contactPhoneCtrl.addListener(_debouncedNotifyParent);
    _totalPotentialCtrl.addListener(_debouncedNotifyParent);
    _bestPotentialCtrl.addListener(_debouncedNotifyParent);
    _feedbackCtrl.addListener(_debouncedNotifyParent);
  }

  // -------------------------------
  // 🔄 PUSH DATA TO PARENT
  // -------------------------------
  void _notifyParent() {
    widget.onDataChanged({
      'partyType': _partyType,
      'visitType': _visitType,
      'nameOfParty': _nameOfPartyCtrl.text,
      'contactNoOfParty': _contactPhoneCtrl.text,
      'expectedActivationDate': _expectedActivationDate,
      'brandSelling': _brandSelling,
      'dealerTotalPotential': _totalPotentialCtrl.text,
      'dealerBestPotential': _bestPotentialCtrl.text,
      'feedbacks': _feedbackCtrl.text,
      // Removed solutionBySalesperson and anyRemarks
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

    _nameOfPartyCtrl.removeListener(_debouncedNotifyParent);
    _contactPhoneCtrl.removeListener(_debouncedNotifyParent);
    _totalPotentialCtrl.removeListener(_debouncedNotifyParent);
    _bestPotentialCtrl.removeListener(_debouncedNotifyParent);
    _feedbackCtrl.removeListener(_debouncedNotifyParent);

    _nameOfPartyCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _totalPotentialCtrl.dispose();
    _bestPotentialCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectActivationDate() async {
    HapticFeedback.selectionClick();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A), // _DvrStyle.cardNavy
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expectedActivationDate = picked);
      _notifyParent(); // Instant update for dates
    }
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
          /// 🏢 PARTY DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Non-Trade Details",
                icon: Icons.business,
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrDropdownField(
                label: "Party Type",
                value: _partyType,
                items: DvrConstants.partyTypeOptions,
                onChanged: (v) {
                  setState(() => _partyType = v);
                  _notifyParent();
                },
              )
              .animate()
              .fadeIn(delay: 50.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrDropdownField(
                label: "Visit Type",
                value: _visitType,
                items: DvrConstants.visitTypeOptions,
                onChanged: (v) {
                  setState(() => _visitType = v);
                  _notifyParent();
                },
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrInputField(controller: _nameOfPartyCtrl, label: "Name of Party")
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrInputField(
                controller: _contactPhoneCtrl,
                label: "Contact No. of Party",
                keyboardType: TextInputType.phone,
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          /// ----------------------------------
          /// 📅 ACTIVATION & POTENTIAL
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Potential & Activation",
                icon: Icons.trending_up,
              )
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          // ✨ UPGRADED DATE PICKER UI
          Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Expected Activation Date *",
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectActivationDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _expectedActivationDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_expectedActivationDate!)
                                  : 'Select a date...',
                              style: TextStyle(
                                color: _expectedActivationDate != null
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
                                fontWeight: _expectedActivationDate != null
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrMultiSelectField(
                label: "Brands in Use",
                items: DvrConstants.brandOptions,
                selectedValues: _brandSelling,
                onChanged: (vals) {
                  setState(() => _brandSelling = vals);
                  _notifyParent();
                },
              )
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          Row(
                children: [
                  Expanded(
                    child: DvrNumberField(
                      controller: _totalPotentialCtrl,
                      label: "Total Potential",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DvrNumberField(
                      controller: _bestPotentialCtrl,
                      label: "Best Potential",
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          /// ----------------------------------
          /// 📝 FEEDBACKS
          /// ----------------------------------
          const DvrFormSectionHeader(title: "Feedback", icon: Icons.rate_review)
              .animate()
              .fadeIn(delay: 450.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrInputField(
                controller: _feedbackCtrl,
                label: "Detailed Feedback",
                maxLines: 3,
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
