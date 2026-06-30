import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/result.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final String _phone;

  @override
  void initState() {
    super.initState();
    _phone = context.read<AuthProvider>().phone!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load(_phone);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: RefreshIndicator(
        onRefresh: () => history.load(_phone, forceRefresh: true),
        child: _buildBody(history),
      ),
    );
  }

  Widget _buildBody(HistoryProvider history) {
    return switch (history.transactionsState) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Failure(:final error) => ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(error.message)),
            Center(
              child: TextButton(
                onPressed: () => history.load(_phone, forceRefresh: true),
                child: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      Success(:final data) when data.isEmpty => ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Aucune transaction.')),
          ],
        ),
      Success(:final data) => ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) => TransactionTile(transaction: data[index]),
        ),
    };
  }
}
