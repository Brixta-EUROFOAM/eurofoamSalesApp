// lib/salesSide/screens/forms/sales_order_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../api/api_service.dart';

import '../../models/sales_order_model.dart';
import '../../models/employee_model.dart';
import '../../models/dealer_model.dart';
import '../../models/destination_model.dart';
import '../../models/outstanding_report_model.dart';
import '../../../widgets/reusable_functions.dart';
import '../salesOrderWidgets/sales_order_constants.dart';
import '../salesOrderWidgets/sales_order_widgets.dart';

class SalesOrderForm extends StatefulWidget {
  final Employee employee;
  final Function(SalesOrder)? onSubmit;

  const SalesOrderForm({super.key, required this.employee, this.onSubmit});

  @override
  State<SalesOrderForm> createState() => _SalesOrderFormState();
}

class _SalesOrderFormState extends State<SalesOrderForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  // ---------------------------
  // 🧠 STATE
  // ---------------------------
  VerifiedDealer? _selectedDealer;
  String? _selectedUnit = "MT";
  String? _salesCategory;
  final _paymentModeController = TextEditingController(text: "BANK TRANSFER");
  DestinationModel? _selectedDestination;
  DateTime? _deliveryDate; // Single source of truth for the date
  List<OutstandingReport> _outstanding = [];
  bool _isLoadingOutstanding = false;

  // ---------------------------
  // 📝 CONTROLLERS
  // ---------------------------
  final c = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();

    const fields = [
      "orderPartyName",
      "partyPhoneNo",
      "partyArea",
      "partyRegion",
      "partyAddress",
      "deliveryArea",
      "deliveryRegion",
      "deliveryAddress",
      "paymentTerms",
      "paymentAmount",
      "receivedPayment",
      "pendingPayment",
      "orderQty",
      "itemPrice",
      "discountPercentage",
      "itemPriceAfterDiscount",
      "itemType",
      "itemGrade",
      "status",
    ];

    for (var f in fields) {
      c[f] = TextEditingController();
    }

    c["paymentAmount"]!.addListener(_calculatePending);
    c["receivedPayment"]!.addListener(_calculatePending);
  }

  void _calculatePending() {
    final total = double.tryParse(c["paymentAmount"]!.text) ?? 0;
    final received = double.tryParse(c["receivedPayment"]!.text) ?? 0;

    final pending = total - received;

    final text = pending >= 0 ? pending.toStringAsFixed(2) : "0.00";

    if (c["pendingPayment"]!.text == text) return;

    // PREVENT LOOP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c["pendingPayment"]!.text = text;
    });
  }

  // ---------------------------
  // 🚀 DEALER SELECT
  // ---------------------------
  Future<void> _selectDealer() async {
    await Future.delayed(Duration.zero);

    final dealer = await openVerifiedDealerSearch(context);

    if (dealer == null) return;

    // ✅ ALWAYS VALID (verified dealer only)
    setState(() {
      _selectedDealer = dealer;
      _outstanding = [];

      c["orderPartyName"]!.text = dealer.dealerPartyName;
      
      // 🛡️ Fallback: Try contactNo1, then contactNo2. 
      c["partyPhoneNo"]!.text = (dealer.contactNo1?.isNotEmpty == true) 
          ? dealer.contactNo1! 
          : dealer.contactNo2 ?? '';
          
      c["partyArea"]!.text = dealer.area ?? '';

      // Ensure the property matches exactly what is in your VerifiedDealer model 
      // c["deliveryLocPincode"] ??= TextEditingController();
      // c["deliveryLocPincode"]!.text = dealer.pinCode ?? '';

      // 🛡️ Dropdown Fix: Match case-insensitively!
      final incomingZone = dealer.zone?.trim() ?? '';
      
      // Find the exact option in your constants list regardless of uppercase/lowercase
      final matchingZone = SalesOrderConstants.regionOptions.firstWhere(
        (opt) => opt.toLowerCase() == incomingZone.toLowerCase(),
        orElse: () => '', // Return empty if no match found
      );

      if (matchingZone.isNotEmpty) {
        c["partyRegion"]!.text = matchingZone; // Uses the properly capitalized version
      } else {
        c["partyRegion"]!.text = ''; 
        debugPrint("WARNING: DB Zone '$incomingZone' not found in options list!");
      }

      // Build the address string using the nicely formatted matchingZone (if found)
      final displayZone = matchingZone.isNotEmpty ? matchingZone : incomingZone;
      final addressParts = [dealer.area, dealer.district, displayZone]
          .where((s) => s != null && s.toString().trim().isNotEmpty)
          .join(', ');
      
      c["partyAddress"]!.text = addressParts;
    });

    // 🔥 FETCH OUTSTANDING
    setState(() => _isLoadingOutstanding = true);

    try {
      final res = await _apiService.fetchOutstandingByVerifiedDealer(dealer.id);

      if (!mounted) return;

      setState(() {
        _outstanding = res;
      });
    } catch (e) {
      debugPrint("Outstanding fetch error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingOutstanding = false);
      }
    }
  }

  Future<void> _selectDestination() async {
    final destination = await openDestinationSearch(context, _apiService);

    if (destination != null) {
      setState(() {
        _selectedDestination = destination;

        c["deliveryAddress"]!.text = destination.destination ?? "";
        c["deliveryArea"]!.text = destination.district ?? "";
        c["deliveryRegion"]!.text = destination.zone ?? "";
      });
    }
  }

  // ---------------------------
  // 🧾 SUBMIT
  // ---------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deliveryDate == null) { // always have "Delivery Date" show as "DO Date"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select Estimated DO Date"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = SalesOrder(
        id: "",
        userId: int.tryParse(widget.employee.id),
        verifiedDealerId: _selectedDealer?.id,
        orderDate: DateTime.now(),

        orderPartyName: c["orderPartyName"]!.text,
        partyPhoneNo: c["partyPhoneNo"]!.text,
        partyArea: c["partyArea"]!.text,
        partyRegion: c["partyRegion"]!.text,
        partyAddress: c["partyAddress"]!.text,

        deliveryArea: c["deliveryArea"]!.text,
        deliveryRegion: c["deliveryRegion"]!.text,
        deliveryAddress: c["deliveryAddress"]!.text,
        deliveryDate: _deliveryDate,
        deliveryLocPincode: c["deliveryLocPincode"]?.text,

        salesCategory: _salesCategory,
        paymentMode: "BANK TRANSFER",
        paymentTerms: c["paymentTerms"]!.text,
        paymentAmount: double.tryParse(c["paymentAmount"]!.text),
        receivedPayment: double.tryParse(c["receivedPayment"]!.text),
        pendingPayment: double.tryParse(c["pendingPayment"]!.text),

        orderQty: double.tryParse(c["orderQty"]!.text),
        orderUnit: _selectedUnit,

        itemPrice: double.tryParse(c["itemPrice"]!.text),
        discountPercentage: double.tryParse(c["discountPercentage"]!.text),
        itemPriceAfterDiscount: double.tryParse(
          c["itemPriceAfterDiscount"]!.text,
        ),

        itemType: c["itemType"]!.text,
        itemGrade: c["itemGrade"]!.text,
        status: c["status"]!.text,
      );

      await _apiService.createSalesOrder(order);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order Created Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // ONLY after success
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ---------------------------
  // 🧱 UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final latest = _outstanding.isNotEmpty ? _outstanding.first : null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -------------------------
            /// 🏢 DEALER
            /// -------------------------
            const SoSectionHeader(title: "Dealer", icon: Icons.store),

            InkWell(
              onTap: _selectDealer,
              child: _selector(
                _selectedDealer?.dealerPartyName ?? "Select Dealer",
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoadingOutstanding)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_isLoadingOutstanding && latest != null)
              _buildOutstandingCard(latest),

            if (!_isLoadingOutstanding &&
                latest == null &&
                _selectedDealer != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "No outstanding data available",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 20),

            /// -------------------------
            /// 👤 PARTY DETAILS
            /// -------------------------
            const SoSectionHeader(title: "Party Details"),

            SoInputField(
              controller: c["orderPartyName"]!,
              label: "Party Name",
              requiredField: true,
            ),

            SoInputField(
              controller: c["partyPhoneNo"]!,
              label: "Phone",
              requiredField: true,
              keyboardType: TextInputType.phone,
            ),

            SoInputField(
              controller: c["partyArea"]!,
              label: "Area",
              requiredField: false,
            ),

            SoDropdownField(
              label: "Region",
              value:
                  SalesOrderConstants.regionOptions.contains(
                    c["partyRegion"]!.text,
                  )
                  ? c["partyRegion"]!.text
                  : null,
              items: SalesOrderConstants.regionOptions,
              onChanged: (v) {
                c["partyRegion"]!.text = v ?? "";
              },
            ),

            SoInputField(
              controller: c["partyAddress"]!,
              label: "Address",
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            /// -------------------------
            /// 🚚 DELIVERY
            /// -------------------------
            const SoSectionHeader(title: "Delivery"),

            InkWell(
              onTap: _selectDestination,
              child: _selector(
                _selectedDestination?.destination ?? "Select Destination",
              ),
            ),

            const SizedBox(height: 20),

            SoInputField(
              controller: c["deliveryArea"]!,
              label: "Delivery Area",
              readOnly: true,
            ),

            SoDropdownField(
              label: "Delivery Region",
              value:
                  SalesOrderConstants.regionOptions.contains(
                    c["deliveryRegion"]!.text,
                  )
                  ? c["deliveryRegion"]!.text
                  : null,
              items: SalesOrderConstants.regionOptions,
              onChanged: (v) =>
                  setState(() => c["deliveryRegion"]!.text = v ?? ""),
            ),

            SoInputField(
              controller: c["deliveryAddress"]!,
              label: "Delivery Address",
              readOnly: true,
              requiredField: true,
            ),

            SoInputField(
              controller: c["deliveryLocPincode"] ??= TextEditingController(),
              label: "Delivery Location Pincode",
              keyboardType: TextInputType.number,
              requiredField: true,
            ),

            const SizedBox(height: 10),

            // ------------------------------------------
            // 🟢 CLICKABLE DATE SELECTOR (POP-UP)
            // ------------------------------------------
            const Text(
              "Estd. DO Date *",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _deliveryDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF0F172A), // Your Navy Blue
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF111827),
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null && picked != _deliveryDate) {
                  setState(() {
                    _deliveryDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _deliveryDate == null
                          ? "Select Estd. DO Date"
                          : DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(_deliveryDate!),
                      style: TextStyle(
                        color: _deliveryDate == null
                            ? Colors.grey.shade500
                            : const Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// -------------------------
            /// 📦 ORDER
            /// -------------------------
            const SoSectionHeader(title: "Order"),

            SoDropdownField(
              label: "Item Type",
              value: c["itemType"]!.text.isNotEmpty
                  ? c["itemType"]!.text
                  : null,
              items: SalesOrderConstants.itemTypes,
              onChanged: (v) => setState(() => c["itemType"]!.text = v ?? ""),
            ),

            SoDropdownField(
              label: "Sales Category",
              value: _salesCategory,
              items: SalesOrderConstants.salesCategories,
              onChanged: (v) => setState(() => _salesCategory = v),
            ),

            SoNumberField(
              controller: c["orderQty"]!,
              label: "Quantity",
              requiredField: true,
            ),

            SoDropdownField(
              label: "Unit",
              value: _selectedUnit,
              items: SalesOrderConstants.unitOptions,
              onChanged: (v) => setState(() => _selectedUnit = v),
            ),

            const SizedBox(height: 20),

            /// -------------------------
            /// 💰 PAYMENT
            /// -------------------------
            const SoSectionHeader(title: "Payment"),

            SoInputField(
              controller: _paymentModeController,
              label: "Payment Mode",
              readOnly: true,
            ),

            SoDropdownField(
              label: "Payment Terms",
              value: c["paymentTerms"]!.text.isNotEmpty
                  ? c["paymentTerms"]!.text
                  : null,
              items: SalesOrderConstants.paymentTermsOptions,
              onChanged: (v) =>
                  setState(() => c["paymentTerms"]!.text = v ?? ""),
              requiredField: true,
            ),

            SoNumberField(
              controller: c["paymentAmount"]!,
              label: "Total Amount",
              requiredField: true,
            ),

            SoNumberField(
              controller: c["receivedPayment"]!,
              label: "Received",
              requiredField: true,
            ),

            SoInputField(
              controller: c["pendingPayment"]!,
              label: "Pending",
              requiredField: true,
              keyboardType: TextInputType.number,
              readOnly: true,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("SUBMIT ORDER"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // OUTSTANDING CARD
  // ===============================
  Widget _buildOutstandingCard(OutstandingReport o) {
    final pending = o.pendingAmt ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Outstanding Summary",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _metric("Pending Amount", pending, Colors.black),
        ],
      ),
    );
  }

  Widget _metric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          "₹ ${value.toStringAsFixed(0)}",
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _selector(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          const Icon(Icons.search),
        ],
      ),
    );
  }
}