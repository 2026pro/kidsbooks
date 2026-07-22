import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client-side QPay service.
///
/// SECURITY: the app NEVER talks to QPay directly and NEVER holds QPay
/// credentials. All QPay calls happen in Cloud Functions (see /functions).
/// This service only invokes callable functions:
///   - createOrder     → validates cart server-side, creates order doc,
///                       creates a QPay invoice, returns {orderId, qrText, deeplinks}
///   - checkQpayPayment → re-checks invoice status (manual fallback button)
class QpayService {
  QpayService(this._functions);
  final FirebaseFunctions _functions;

  Future<CreateOrderResult> createOrder({
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? address,
  }) async {
    final res = await _functions.httpsCallable('createOrder').call({
      'items': items, // [{bookId, format, qty}] — prices computed server-side
      'address': address,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    return CreateOrderResult(
      orderId: data['orderId'],
      qrText: data['qrText'],
      deeplinks: List<String>.from(data['deeplinks'] ?? []),
    );
  }

  /// Manual "Check payment" fallback. The primary confirmation path is the
  /// QPay callback → Cloud Function → order doc update → Firestore stream.
  Future<bool> checkPayment(String orderId) async {
    final res = await _functions
        .httpsCallable('checkQpayPayment')
        .call({'orderId': orderId});
    return (res.data as Map)['paid'] == true;
  }
}

class CreateOrderResult {
  final String orderId;
  final String qrText;
  final List<String> deeplinks;
  const CreateOrderResult({
    required this.orderId,
    required this.qrText,
    required this.deeplinks,
  });
}

final qpayServiceProvider =
    Provider((ref) => QpayService(FirebaseFunctions.instance));
