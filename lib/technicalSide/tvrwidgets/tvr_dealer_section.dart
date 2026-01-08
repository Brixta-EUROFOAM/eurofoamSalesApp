import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/tvr_constants.dart';
import '../tvrwidgets/tvr_form_widgets.dart';

class TvrDealerSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;

  final Function(String, dynamic) onUpdate;
  final VoidCallback onDealerSearch;
  final VoidCallback onLocationFetch;
  final VoidCallback onPickPhoto;
  final VoidCallback onSelectSupplyDate;

  const TvrDealerSection({
    super.key,
    required this.controllers,
    required this.values,
    required this.onUpdate,
    required this.onDealerSearch,
    required this.onLocationFetch,
    required this.onPickPhoto,
    required this.onSelectSupplyDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        /// ---------------- DEALER SELECTION ----------------
        TvrSearchTile(
          label: 'Tap to Search Dealer (Optional)',
          value: values['selectedDealerName'],
          onTap: onDealerSearch,
        ),

        const SizedBox(height: 16),

        /// Auto-filled from dealer, editable
        TvrInputField(
          label: 'Dealer / Sub-Dealer Name',
          controller: controllers['partyName']!,
        ),

        const SizedBox(height: 16),

        /// Auto-filled from dealer, editable
        TvrInputField(
          label: 'Phone / WhatsApp No.',
          controller: controllers['phone']!,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 16),

        /// ---------------- LOCATION ----------------
        TvrLocationFetchWidget(
          lat: controllers['latitude']!,
          lng: controllers['longitude']!,
          isLoading: values['isFetchingLocation'] == true,
          onFetch: onLocationFetch,
        ),

        const SizedBox(height: 16),

        /// ---------------- VISIT META ----------------
        TvrDropdownField(
          label: 'Visit Category',
          value: values['selectedVisitCategory'],
          items: TvrConstants.visitCategoryOptions,
          onChanged: (v) => onUpdate('selectedVisitCategory', v),
        ),

        const SizedBox(height: 16),

        TvrDropdownField(
          label: 'Influencer Type',
          value: values['selectedInfluencerType'],
          items: const ['Dealer', 'Sub-Dealer'],
          onChanged: (v) => onUpdate('selectedInfluencerType', v),
        ),

        /// ---------------- LOCATION & REGION ----------------
        const TvrSectionHeader(title: 'Location & Region'),

        Row(
          children: [
            Expanded(
              child: TvrDropdownField(
                label: 'Region',
                value: values['selectedRegion'],
                items: TvrConstants.regionOptions,
                onChanged: (v) => onUpdate('selectedRegion', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TvrInputField(
                label: 'Area',
                controller: controllers['area']!,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Address',
          controller: controllers['siteAddress']!,
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        /// ---------------- DEALER PHOTO ----------------
        TvrSelectionCard(
          label: values['sitePhotoFile'] != null
              ? 'Photo Selected'
              : 'Capture Dealer Photo (Optional)',
          icon: Icons.camera_enhance,
          isDone: values['sitePhotoFile'] != null,
          onTap: onPickPhoto,
        ),

        /// ---------------- BUSINESS INFO ----------------
        const TvrSectionHeader(title: 'Business Info'),

        TvrInputField(
          label: 'Productivity',
          controller: controllers['productivity']!,
        ),

        const SizedBox(height: 16),

        TvrMultiSelectField(
          label: 'Brands in Use / Selling',
          items: TvrConstants.brandOptions,
          selectedValues: values['brandsInUse'] ?? [],
          onChanged: (v) => onUpdate('brandsInUse', v),
        ),

        /// ---------------- CONVERSION ----------------
        const TvrSectionHeader(title: 'Conversion'),

        TvrSwitchField(
          label: 'Is Bag Picked?',
          value: values['isBagPicked'] ?? false,
          onChanged: (v) {
            onUpdate('isBagPicked', v);
            onUpdate('isConverted', v); // implicit conversion
          },
        ),

        if (values['isBagPicked'] == true) ...[
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TvrInputField(
                  label: 'Quantity',
                  controller: controllers['qty']!,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TvrDropdownField(
                  label: 'Unit',
                  value: values['selectedUnit'],
                  items: const ['Bags'],
                  onChanged: (v) => onUpdate('selectedUnit', v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TvrInputField(
            label: 'Rate per Bag',
            controller: controllers['rate']!,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          /// Supply Date
          InkWell(
            onTap: onSelectSupplyDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: TvrConstants.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: TvrConstants.cardNavy, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    values['supplyDate'] != null
                        ? DateFormat('dd MMM yyyy')
                            .format(values['supplyDate'])
                        : 'Select Date of Supply (of Bags)',
                    style: TextStyle(
                      color: values['supplyDate'] != null
                          ? TvrConstants.textDark
                          : TvrConstants.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        /// ---------------- REMARKS ----------------
        const TvrSectionHeader(title: 'Remarks'),

        TvrInputField(
          label: 'Remarks',
          controller: controllers['remarks']!,
          maxLines: 2,
        ),
      ],
    );
  }
}