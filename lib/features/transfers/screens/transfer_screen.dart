import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/transfer_provider.dart';
import '../widgets/numeric_keypad.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _recipientController = TextEditingController();
  String _amountInput = '';

  double get _amount => double.tryParse(_amountInput.isEmpty ? '0' : _amountInput) ?? 0;

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (key == '.' && _amountInput.contains('.')) return;
    if (_amountInput.isEmpty && key == '.') {
      setState(() => _amountInput = '0.');
      return;
    }
    setState(() => _amountInput += key);
  }

  void _onBackspace() {
    if (_amountInput.isEmpty) return;
    setState(() => _amountInput = _amountInput.substring(0, _amountInput.length - 1));
  }

  Future<void> _confirmAndSubmit() async {
    final recipient = _recipientController.text.trim();
    if (recipient.isEmpty) {
      _showSnack('Entrez le numéro du destinataire.');
      return;
    }
    if (_amount <= 0) {
      _showSnack('Entrez un montant valide.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le transfert'),
        content: Text(
          'Envoyer ${CurrencyFormatter.format(_amount)} à $recipient ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final fromPhone = context.read<AuthProvider>().phone!;
    final success = await context.read<TransferProvider>().submit(
          fromPhone: fromPhone,
          toPhone: recipient,
          amount: _amount,
        );

    if (!mounted) return;
    if (success) {
      _showSnack('Transfert effectué avec succès.');
      Navigator.of(context).pop(true);
    } else {
      final error = context.read<TransferProvider>().error;
      _showSnack(error?.message ?? 'Le transfert a échoué.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<TransferProvider>().status == SubmitStatus.submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Transférer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _recipientController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro du destinataire',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                CurrencyFormatter.format(_amount),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              NumericKeypad(onKeyTap: _onKeyTap, onBackspace: _onBackspace),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : _confirmAndSubmit,
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
