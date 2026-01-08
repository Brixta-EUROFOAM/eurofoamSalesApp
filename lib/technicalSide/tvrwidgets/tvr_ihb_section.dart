import 'package:flutter/material.dart';
import '../utils/tvr_constants.dart';
import '../tvrwidgets/tvr_form_widgets.dart';

class TvrIhbSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;

  final Function(String, dynamic) onUpdate;
  final VoidCallback onSiteSearch;
  final VoidCallback onMasonSearch;
  final VoidCallback onLocationFetch;
  final VoidCallback onPickPhoto;

  const TvrIhbSection({
    super.key,
    required this.controllers,
    required this.values,
    required this.onUpdate,
    required this.onSiteSearch,
    required this.onMasonSearch,
    required this.onLocationFetch,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// ---------------- SITE SELECTION ----------------
        TvrSearchTile(
          label: 'Select Construction Site *',
          value: values['selectedSiteName'],
          onTap: onSiteSearch,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Concerned Person',
          controller: controllers['concernedPerson']!,
          readOnly: true,
        ),

        const SizedBox(height: 16),

        /// ---------------- VISIT META ----------------
        TvrDropdownField(
          label: 'Visit Type',
          value: values['selectedVisitType'],
          items: const [
            'Site Visit',
            'Site Service',
            'Quality Complaint',
            'Conversion',
          ],
          onChanged: (v) => onUpdate('selectedVisitType', v),
        ),

        const SizedBox(height: 16),

        TvrDropdownField(
          label: 'Site Visit Type',
          value: values['selectedSiteVisitType'],
          items: const ['Planned', 'Unplanned'],
          onChanged: (v) => onUpdate('selectedSiteVisitType', v),
        ),

        const SizedBox(height: 16),

        TvrDropdownField(
          label: 'Visit Category',
          value: values['selectedVisitCategory'],
          items: TvrConstants.visitCategoryOptions,
          onChanged: (v) => onUpdate('selectedVisitCategory', v),
        ),

        const SizedBox(height: 16),

        /// ---------------- SITE OWNER ----------------
        TvrInputField(
          label: 'Site Owner Name',
          controller: controllers['partyName']!,
          // auto-filled from site, but editable
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Phone / WhatsApp No.',
          controller: controllers['whatsapp']!,
          keyboardType: TextInputType.phone,
          // auto-filled from site, but editable
        ),

        const SizedBox(height: 16),

        /// ---------------- LOCATION ----------------
        TvrLocationFetchWidget(
          lat: controllers['latitude']!,
          lng: controllers['longitude']!,
          isLoading: values['isFetchingLocation'] == true,
          onFetch: onLocationFetch,
        ),

        /// ---------------- SITE INFO ----------------
        const TvrSectionHeader(title: 'Site Info'),

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
          label: 'Site Address',
          controller: controllers['siteAddress']!,
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Market Name',
          controller: controllers['marketName']!,
        ),

        const SizedBox(height: 16),

        /// ---------------- SITE PHOTO ----------------
        // taken with CheckOut photo

        Row(
          children: [
            Expanded(
              child: TvrInputField(
                label: 'Area (SqFt)',
                controller: controllers['constArea']!,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TvrDropdownField(
                label: 'Stage',
                value: values['selectedStage'],
                items: TvrConstants.stageOptions,
                onChanged: (v) => onUpdate('selectedStage', v),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        TvrMultiSelectField(
          label: 'Brands in Use',
          items: TvrConstants.brandOptions,
          selectedValues: values['brandsInUse'] ?? [],
          onChanged: (v) => onUpdate('brandsInUse', v),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TvrInputField(
                label: 'Current Price',
                controller: controllers['rate']!,
                keyboardType: TextInputType.number,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TvrInputField(
                label: 'Site Stock',
                controller: controllers['siteStock']!,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Estimated Requirement',
          controller: controllers['estRequirement']!,
          keyboardType: TextInputType.number,
        ),

        TvrInputField(
          label: 'Site Supplying Dealer',
          controller: controllers['supplyingDealer']!,
          isRequired: false,
        ),

        /// ---------------- CONVERSION ----------------
        const TvrSectionHeader(title: 'Conversion'),

        TvrSwitchField(
          label: 'Is Converted?',
          value: values['isConverted'] ?? false,
          onChanged: (v) => onUpdate('isConverted', v),
        ),

        if (values['isConverted'] == true) ...[
          const SizedBox(height: 12),

          TvrDropdownField(
            label: 'Conversion Type',
            value: values['conversionType'],
            items: const ['New', 'Retention'],
            onChanged: (v) => onUpdate('conversionType', v),
          ),

          const SizedBox(height: 16),

          TvrDropdownField(
            label: 'From Brand',
            value: values['conversionFromBrand'],
            items: TvrConstants.brandOptions,
            onChanged: (v) => onUpdate('conversionFromBrand', v),
          ),

          const SizedBox(height: 16),

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
            label: 'Converted Brand Dealer (Best)',
            controller: controllers['nearbyDealer']!,
            isRequired: true,
          ),
        ],

        /// ---------------- TECH SERVICES ----------------
        const TvrSectionHeader(title: 'Technical Services'),

        TvrSwitchField(
          label: 'Tech Service Given?',
          value: values['isTechService'] ?? false,
          onChanged: (v) => onUpdate('isTechService', v),
        ),

        if (values['isTechService'] == true) ...[
          const SizedBox(height: 12),

          TvrDropdownField(
            label: 'Service Type',
            value: values['selectedServiceType'],
            items: TvrConstants.serviceTypeOptions,
            onChanged: (v) => onUpdate('selectedServiceType', v),
          ),

          const SizedBox(height: 16),

          TvrInputField(
            label: 'Description',
            controller: controllers['serviceDesc']!,
            maxLines: 2,
            isRequired: false,
          ),
        ],

        const SizedBox(height: 16),

        /// ---------------- INFLUENCER ----------------
        const TvrSectionHeader(title: 'Influencer / Mason'),

        TvrSearchTile(
          label: 'Link Registered Mason (Optional)',
          value: values['selectedMasonName'],
          onTap: onMasonSearch,
        ),

        const SizedBox(height: 16),

        TvrDropdownField(
          label: 'Influencer Type',
          value: values['selectedInfluencerType'],
          items: TvrConstants.influencerTypeOptions,
          onChanged: (v) => onUpdate('selectedInfluencerType', v),
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Name',
          controller: controllers['influencerName']!,
          isRequired: true,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Phone',
          controller: controllers['influencerPhone']!,
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Influencer Productivity',
          controller: controllers['productivity']!,
          isRequired: false,
        ),

        const SizedBox(height: 16),

        TvrSwitchField(
          label: 'Enrolled in Scheme?',
          value: values['isSchemeEnrolled'] ?? false,
          onChanged: (v) => onUpdate('isSchemeEnrolled', v),
        ),

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