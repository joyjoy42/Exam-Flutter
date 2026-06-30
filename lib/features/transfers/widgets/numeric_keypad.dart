import 'package:flutter/material.dart';

/// Custom numeric pad for amount entry, per spec ("Saisie du montant via
/// un pavé numérique personnalisé") instead of the platform keyboard —
/// keeps the input experience consistent across Android/iOS.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key, required this.onKeyTap, required this.onBackspace});

  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: _keys.map((key) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => key == '⌫' ? onBackspace() : onKeyTap(key),
          child: Center(
            child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }
}
