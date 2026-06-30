import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/result.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/bills_provider.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late final String _phone;

  @override
  void initState() {
    super.initState();
    _phone = context.read<AuthProvider>().phone!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillsProvider>().loadFactures(_phone);
    });
  }

  Future<void> _pay() async {
    final bills = context.read<BillsProvider>();
    final success = await bills.payCheckedFactures(_phone);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factures payées avec succès.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bills.paymentError?.message ?? 'Le paiement a échoué.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payer une facture')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: AppConstants.billProviders.map((provider) {
                final selected = provider == bills.selectedProvider;
                return ChoiceChip(
                  label: Text(provider),
                  selected: selected,
                  onSelected: (_) => context.read<BillsProvider>().selectProvider(provider, _phone),
                );
              }).toList(),
            ),
          ),
          Expanded(child: _buildFacturesList(bills)),
          _buildPayBar(bills),
        ],
      ),
    );
  }

  Widget _buildFacturesList(BillsProvider bills) {
    return switch (bills.facturesState) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Failure(:final error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.message),
              TextButton(
                onPressed: () => context.read<BillsProvider>().loadFactures(_phone, forceRefresh: true),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      Success(:final data) when data.isEmpty =>
        const Center(child: Text('Aucune facture impayée pour ce fournisseur.')),
      Success(:final data) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final facture = data[index];
            final checked = bills.selectedFactureIds.contains(facture.id);
            return CheckboxListTile(
              value: checked,
              onChanged: (_) => context.read<BillsProvider>().toggleFacture(facture.id),
              title: Text(facture.reference.isEmpty ? facture.provider : facture.reference),
              subtitle: facture.dueDate != null
                  ? Text('Échéance : ${facture.dueDate!.day}/${facture.dueDate!.month}/${facture.dueDate!.year}')
                  : null,
              secondary: Text(CurrencyFormatter.format(facture.amount)),
            );
          },
        ),
    };
  }

  Widget _buildPayBar(BillsProvider bills) {
    final submitting = bills.paymentStatus == PaymentStatus.submitting;
    final hasSelection = bills.selectedFactureIds.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (!hasSelection || submitting) ? null : _pay,
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(hasSelection
                    ? 'Payer ${CurrencyFormatter.format(bills.selectedTotal)}'
                    : 'Sélectionnez des factures'),
          ),
        ),
      ),
    );
  }
}
