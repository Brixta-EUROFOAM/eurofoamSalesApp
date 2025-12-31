import 'package:flutter/material.dart';
import 'package:salesmanapp/features/technicalPjpcreate/pjp_create_results.dart';

class PjpCreateOption {
  final PjpCreateMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const PjpCreateOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}
