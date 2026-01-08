// lib/technicalSide/utils/tvr_constants.dart
import 'package:flutter/material.dart';

class TvrConstants {
  // --- Dropdown Options ---
  static const List<String> customerTypeOptions = [
    'IHB/Site',
    'Engineer/Architect',
    'Contractor/Head Mason',
    'Channel Partner(Dealer/Sub-Dealer)',
    'Competitor Channel Partner (Dealer/Sub-Dealer)',
  ];

  static const List<String> stageOptions = [
    'Foundation', 'Plinth Level', 'Brick Work', 'Column Work', 'Lintel Work', 'Slab Work', 'Plaster Work',
  ];

  static const List<String> brandOptions = [
    'Best', 'Star', 'Dalmia', 'Black Tiger', 'Topcem', 'Taj', 'Amrit', 'Max', 'Ambuja', 'ACC', 'other',
  ];

  static const List<String> serviceTypeOptions = [
    'Slab Supervision', 'CTV Demo', 'NDT', 'Good Construction Practices',
  ];

  static const List<String> techActivityOptions = [
    'Site Visit', 'IHB Meet', 'Contractor/Mason Meet', 'Consumer Awareness Camp',
  ];

  static const List<String> influencerTypeOptions = [
    'Head Mason', 'Mason', 'PC', 'Engineer/Architect'
  ];

  static const List<String> visitCategoryOptions = ['New', 'Follow Up'];

  static const List<String> regionOptions = [
    "All Region", "Kamrup", "Upper Assam", "Lower Assam", "Central Assam", "Barak Valley", "North Bank", "Meghalaya", "Mizoram", "Nagaland", "Tripura",
  ];

  // --- Theme Colors ---
  static const Color surfaceWhite = Colors.white;
  static const Color cardNavy = Color(0xFF0F172A);
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color inputFill = Color(0xFFF9FAFB);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
}