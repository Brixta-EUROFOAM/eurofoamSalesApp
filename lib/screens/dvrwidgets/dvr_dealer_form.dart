// lib/screens/dvrwidgets/dvr_dealer_form.dart

import 'dart:async'; // 🔥 ADDED FOR DEBOUNCE
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS
import 'package:salesmanapp/technicalSide/utils/dvr_constants.dart';
import 'dvr_form_widgets.dart';

class DvrDealerFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const DvrDealerFormWidget({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<DvrDealerFormWidget> createState() => _DvrDealerFormWidgetState();
}

class _DvrDealerFormWidgetState extends State<DvrDealerFormWidget> {
  // -------------------------------
  // 🧠 DROPDOWN STATES
  // -------------------------------
  String? _dealerType;
  String? _visitType;
  List<String> _brandSelling = [];

  // 🚀 O(1) CPU THROTTLING
  Timer? _debounce;

  // -------------------------------
  // 📝 CONTROLLERS
  // -------------------------------
  final TextEditingController _dealerTotalPotentialCtrl =
      TextEditingController();
  final TextEditingController _dealerBestPotentialCtrl =
      TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _contactPhoneCtrl = TextEditingController();
  final TextEditingController _todayOrderCtrl = TextEditingController();
  final TextEditingController _todayCollectionCtrl = TextEditingController();
  final TextEditingController _feedbackCtrl = TextEditingController();
  final TextEditingController _solutionCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  // 🚀 CRITICAL FIX: Attach listeners to Number Fields here instead of in the widget tree
  @override
  void initState() {
    super.initState();
    _dealerTotalPotentialCtrl.addListener(_debouncedNotifyParent);
    _dealerBestPotentialCtrl.addListener(_debouncedNotifyParent);
    _todayOrderCtrl.addListener(_debouncedNotifyParent);
    _todayCollectionCtrl.addListener(_debouncedNotifyParent);
  }

  // -------------------------------
  // 🔄 PUSH DATA TO PARENT
  // -------------------------------
  void _notifyParent() {
    widget.onDataChanged({
      'dealerType': _dealerType,
      'visitType': _visitType,
      'brandSelling': _brandSelling,
      'dealerTotalPotential': _dealerTotalPotentialCtrl.text,
      'dealerBestPotential': _dealerBestPotentialCtrl.text,
      'contactPerson': _contactPersonCtrl.text,
      'contactPersonPhoneNo': _contactPhoneCtrl.text,
      'todayOrderMt': _todayOrderCtrl.text,
      'todayCollectionRupees': _todayCollectionCtrl.text,
      'feedbacks': _feedbackCtrl.text,
      'solutionBySalesperson': _solutionCtrl.text,
      'anyRemarks': _remarksCtrl.text,
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

    _dealerTotalPotentialCtrl.removeListener(_debouncedNotifyParent);
    _dealerBestPotentialCtrl.removeListener(_debouncedNotifyParent);
    _todayOrderCtrl.removeListener(_debouncedNotifyParent);
    _todayCollectionCtrl.removeListener(_debouncedNotifyParent);

    _dealerTotalPotentialCtrl.dispose();
    _dealerBestPotentialCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _todayOrderCtrl.dispose();
    _todayCollectionCtrl.dispose();
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
          /// 📌 VISIT DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Visit Details",
                icon: Icons.storefront,
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrDropdownField(
                label: "Dealer Type",
                value: _dealerType,
                items: DvrConstants.dealerTypeOptions,
                onChanged: (v) {
                  setState(() => _dealerType = v);
                  _notifyParent(); // Instant update for dropdowns
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
                  _notifyParent(); // Instant update for dropdowns
                },
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrMultiSelectField(
                label: "Brand Selling",
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
          /// 📊 POTENTIAL DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Dealer Potential",
                icon: Icons.bar_chart,
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrNumberField(
                controller: _dealerTotalPotentialCtrl,
                label: "Dealer Total Potential",
                // Removed onChanged, handled securely by listener in initState
              )
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrNumberField(
                controller: _dealerBestPotentialCtrl,
                label: "Dealer Best Potential",
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          /// ----------------------------------
          /// 👤 CONTACT DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Contact Details",
                icon: Icons.person,
              )
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrInputField(
                controller: _contactPersonCtrl,
                label: "Contact Person",
                onChanged: (_) =>
                    _debouncedNotifyParent(), // DvrInputField supports onChanged
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrInputField(
                controller: _contactPhoneCtrl,
                label: "Contact Phone",
                keyboardType: TextInputType.phone,
                onChanged: (_) => _debouncedNotifyParent(),
              )
              .animate()
              .fadeIn(delay: 450.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          /// ----------------------------------
          /// 💰 SALES DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
                title: "Sales Details",
                icon: Icons.currency_rupee,
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrNumberField(
                controller: _todayOrderCtrl,
                label: "Today's Order (MT)",
              )
              .animate()
              .fadeIn(delay: 550.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          DvrNumberField(
                controller: _todayCollectionCtrl,
                label: "Today's Collection (₹)",
              )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          /// ----------------------------------
          /// 📝 FEEDBACKS
          /// ----------------------------------
          const DvrFormSectionHeader(title: "Feedback", icon: Icons.rate_review)
              .animate()
              .fadeIn(delay: 650.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          DvrInputField(
                controller: _feedbackCtrl,
                label: "Feedbacks",
                maxLines: 3,
                onChanged: (_) => _debouncedNotifyParent(),
              )
              .animate()
              .fadeIn(delay: 700.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
