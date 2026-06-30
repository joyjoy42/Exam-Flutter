import 'package:flutter/material.dart';

class QuickActionData {
  const QuickActionData({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// "Transférer", "Payer", "Historique" — the three primary actions called
/// out in the spec, laid out as equal-width tappable columns.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});

  final List<QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions
          .map((a) => Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: a.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(a.icon, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
