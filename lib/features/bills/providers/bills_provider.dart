import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/result.dart';
import '../../../core/utils/idempotency.dart';
import '../../../models/facture.dart';
import '../../../models/transfer_request.dart';
import '../data/bills_repository.dart';

enum PaymentStatus { idle, submitting, success, error }

class BillsProvider extends ChangeNotifier {
  BillsProvider(this._repository);

  final BillsRepository _repository;

  String selectedProvider = AppConstants.billProviders.first;
  Result<List<Facture>> facturesState = const Loading();
  final Set<String> selectedFactureIds = {};
  PaymentStatus paymentStatus = PaymentStatus.idle;
  AppException? paymentError;

  double get selectedTotal {
    final factures = switch (facturesState) {
      Success(:final data) => data,
      _ => const <Facture>[],
    };
    return factures
        .where((f) => selectedFactureIds.contains(f.id))
        .fold(0.0, (sum, f) => sum + f.amount);
  }

  Future<void> selectProvider(String provider, String phone) async {
    selectedProvider = provider;
    selectedFactureIds.clear();
    paymentStatus = PaymentStatus.idle;
    await loadFactures(phone);
  }

  Future<void> loadFactures(String phone, {bool forceRefresh = false}) async {
    facturesState = const Loading();
    notifyListeners();
    facturesState = await _repository.getUnpaidFactures(selectedProvider, phone, forceRefresh: forceRefresh);
    notifyListeners();
  }

  void toggleFacture(String factureId) {
    if (!selectedFactureIds.remove(factureId)) {
      selectedFactureIds.add(factureId);
    }
    notifyListeners();
  }

  Future<bool> payCheckedFactures(String phone) async {
    if (selectedFactureIds.isEmpty) return false;
    paymentStatus = PaymentStatus.submitting;
    paymentError = null;
    notifyListeners();

    try {
      await _repository.payFactures(PayFacturesRequest(
        phone: phone,
        factureIds: selectedFactureIds.toList(),
        idempotencyKey: newIdempotencyKey(),
      ));
      paymentStatus = PaymentStatus.success;
      selectedFactureIds.clear();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      paymentStatus = PaymentStatus.error;
      paymentError = e;
      notifyListeners();
      return false;
    }
  }
}
