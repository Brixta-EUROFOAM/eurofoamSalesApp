import 'package:flutter/material.dart';
import '../utils/tvr_constants.dart';
import '../tvrwidgets/tvr_form_widgets.dart';

class TvrInfluencerSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;

  final Function(String, dynamic) onUpdate;
  final VoidCallback onMasonSearch;
  final VoidCallback onLocationFetch;

  const TvrInfluencerSection({
    super.key,
    required this.controllers,
    required this.values,
    required this.onUpdate,
    required this.onMasonSearch,
    required this.onLocationFetch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// ---------------- INFLUENCER SELECTION ----------------
        TvrSearchTile(
          label: 'Link Registered Profile (Optional)',
          value: values['selectedMasonName'],
          onTap: onMasonSearch,
        ),

        const SizedBox(height: 16),

        /// ---------------- BASIC INFO ----------------
        TvrDropdownField(
          label: 'Influencer Type',
          value: values['selectedInfluencerType'],
          items: const [
            'Mason',
            'Head Mason',
            'Contractor',
            'Engineer',
            'Architect',
          ],
          onChanged: (v) => onUpdate('selectedInfluencerType', v),
          isRequired: true,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Name',
          controller: controllers['influencerName']!,
          isRequired: true,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Phone / WhatsApp',
          controller: controllers['influencerPhone']!,
          keyboardType: TextInputType.phone,
          isRequired: true,
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
        const TvrSectionHeader(title: 'Details'),

        Row(
          children: [
            Expanded(
              child: TvrDropdownField(
                label: 'Region',
                value: values['selectedRegion'],
                items: TvrConstants.regionOptions,
                onChanged: (v) => onUpdate('selectedRegion', v),
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TvrInputField(
                label: 'Area',
                controller: controllers['area']!,
                isRequired: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Address',
          controller: controllers['siteAddress']!,
          maxLines: 2,
          isRequired: true,
        ),

        /// ---------------- VISIT META ----------------
        TvrDropdownField(
          label: 'Visit Category',
          value: values['selectedVisitCategory'],
          items: TvrConstants.visitCategoryOptions,
          onChanged: (v) => onUpdate('selectedVisitCategory', v),
          isRequired: true,
        ),

        const SizedBox(height: 16),

        TvrInputField(
          label: 'Purpose of Visit',
          controller: controllers['purposeOfVisit']!,
          isRequired: false,
        ),

        TvrInputField(
          label: 'Productivity',
          controller: controllers['productivity']!,
          isRequired: false,
        ),

        const SizedBox(height: 16),

        TvrMultiSelectField(
          label: 'Preferred Brands',
          items: TvrConstants.brandOptions,
          selectedValues: values['brandsInUse'] ?? [],
          onChanged: (v) => onUpdate('brandsInUse', v),
          isRequired: true,
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
