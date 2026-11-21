import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NumberField extends StatelessWidget {
  const NumberField({super.key, 
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixText: suffix,
      ),
    );
  }
}
