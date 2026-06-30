import 'package:flutter/foundation.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/utils/idempotency.dart';
import '../../../models/transfer_request.dart';
import '../data/transfer_repository.dart';

enum SubmitStatus { idle, submitting, success, error }

class TransferProvider extends ChangeNotifier {
  TransferProvider(this._repository);

  final TransferRepository _repository;

  SubmitStatus status = SubmitStatus.idle;
  AppException? error;

  Future<bool> submit({
    required String fromPhone,
    required String toPhone,
    required double amount,
    String? note,
  }) async {
    status = SubmitStatus.submitting;
    error = null;
    notifyListeners();

    try {
      await _repository.transfer(TransferRequest(
        fromPhone: fromPhone,
        toPhone: toPhone,
        amount: amount,
        note: note,
        idempotencyKey: newIdempotencyKey(),
      ));
      status = SubmitStatus.success;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      status = SubmitStatus.error;
      error = e;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    status = SubmitStatus.idle;
    error = null;
  }
}
