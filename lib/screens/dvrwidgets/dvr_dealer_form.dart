// lib/screens/dvrwidgets/dvr_dealer_form.dart

import 'package:flutter/material.dart';
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

  // -------------------------------
  // 📝 CONTROLLERS
  // -------------------------------
  final TextEditingController _dealerTotalPotentialCtrl = TextEditingController();
  final TextEditingController _dealerBestPotentialCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _contactPhoneCtrl = TextEditingController();
  final TextEditingController _todayOrderCtrl = TextEditingController();
  final TextEditingController _todayCollectionCtrl = TextEditingController();
  final TextEditingController _feedbackCtrl = TextEditingController();
  final TextEditingController _solutionCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

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

  @override
  void dispose() {
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
          ),

          DvrDropdownField(
            label: "Dealer Type",
            value: _dealerType,
            items: DvrConstants.dealerTypeOptions,
            onChanged: (v) {
              setState(() => _dealerType = v);
              _notifyParent();
            },
          ),

          const SizedBox(height: 16),

          DvrDropdownField(
            label: "Visit Type",
            value: _visitType,
            items: DvrConstants.visitTypeOptions,
            onChanged: (v) {
              setState(() => _visitType = v);
              _notifyParent();
            },
          ),

          const SizedBox(height: 16),

          DvrMultiSelectField(
            label: "Brand Selling",
            items: DvrConstants.brandOptions,
            selectedValues: _brandSelling,
            onChanged: (vals) {
              setState(() => _brandSelling = vals);
              _notifyParent();
            },
          ),

          /// ----------------------------------
          /// 📊 POTENTIAL DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
            title: "Dealer Potential",
            icon: Icons.bar_chart,
          ),

          DvrNumberField(
            controller: _dealerTotalPotentialCtrl,
            label: "Dealer Total Potential",
          ),

          const SizedBox(height: 16),

          DvrNumberField(
            controller: _dealerBestPotentialCtrl,
            label: "Dealer Best Potential",
          ),

          /// ----------------------------------
          /// 👤 CONTACT DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
            title: "Contact Details",
            icon: Icons.person,
          ),

          DvrInputField(
            controller: _contactPersonCtrl,
            label: "Contact Person",
            onChanged: (_) => _notifyParent(),
          ),

          const SizedBox(height: 16),

          DvrInputField(
            controller: _contactPhoneCtrl,
            label: "Contact Phone",
            keyboardType: TextInputType.phone,
            onChanged: (_) => _notifyParent(),
          ),

          /// ----------------------------------
          /// 💰 SALES DETAILS
          /// ----------------------------------
          const DvrFormSectionHeader(
            title: "Sales Details",
            icon: Icons.currency_rupee,
          ),

          DvrNumberField(
            controller: _todayOrderCtrl,
            label: "Today's Order (MT)",
          ),

          const SizedBox(height: 16),

          DvrNumberField(
            controller: _todayCollectionCtrl,
            label: "Today's Collection (₹)",
          ),

          /// ----------------------------------
          /// 📝 FEEDBACKS
          /// ----------------------------------
          const DvrFormSectionHeader(
            title: "Feedback",
            icon: Icons.rate_review,
          ),

          DvrInputField(
            controller: _feedbackCtrl,
            label: "Feedbacks",
            maxLines: 3,
            onChanged: (_) => _notifyParent(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
