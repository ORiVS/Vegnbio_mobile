import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';

class LoyaltySummary {
  final int pointsBalance;
  final String earnRatePerEuro; // string pour éviter les soucis de décimales
  final String redeemRateEuroPerPoint;

  LoyaltySummary({
    required this.pointsBalance,
    required this.earnRatePerEuro,
    required this.redeemRateEuroPerPoint,
  });

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    return LoyaltySummary(
      pointsBalance: (json['points_balance'] ?? 0) as int,
      earnRatePerEuro: (json['earn_rate_per_euro'] ?? '1.0').toString(),
      redeemRateEuroPerPoint: (json['redeem_rate_euro_per_point'] ?? '0.01').toString(),
    );
  }
}

class LoyaltyTransaction {
  final int id;
  final String kind; // EARN, SPEND, ADJUST
  final int points;
  final String reason;
  final int? relatedOrderId;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.kind,
    required this.points,
    required this.reason,
    required this.relatedOrderId,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> j) {
    return LoyaltyTransaction(
      id: j['id'] as int,
      kind: j['kind'] as String,
      points: j['points'] as int,
      reason: (j['reason'] ?? '') as String,
      relatedOrderId: j['related_order_id'] as int?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

final loyaltySummaryProvider = FutureProvider<LoyaltySummary>((ref) async {
  final res = await ApiService.instance.dio.get('/api/fidelite/points/');
  return LoyaltySummary.fromJson(res.data as Map<String, dynamic>);
});

final loyaltyTransactionsProvider = FutureProvider<List<LoyaltyTransaction>>((ref) async {
  final res = await ApiService.instance.dio.get('/api/fidelite/transactions/');
  final list = (res.data as List).map((e) => LoyaltyTransaction.fromJson(e)).toList();
  return list;
});

final joinLoyaltyProvider = FutureProvider.autoDispose<String?>((ref) async {
  final res = await ApiService.instance.dio.post('/api/fidelite/join/');
  return (res.data as Map)['message']?.toString();
});
