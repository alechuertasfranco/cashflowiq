// lib/shared/models/investment_fund_snapshot.dart

import 'package:cashflowiq/core/utils/format.dart';

class InvestmentFundSnapshot {
  final String id;
  final String fundId;
  final DateTime snapshotDate;
  final double value;

  const InvestmentFundSnapshot({
    required this.id,
    required this.fundId,
    required this.snapshotDate,
    required this.value,
  });

  factory InvestmentFundSnapshot.fromJson(Map<String, dynamic> json) {
    return InvestmentFundSnapshot(
      id: json['id'].toString(),
      fundId: json['investment_fund_id'].toString(),
      snapshotDate: DateTime.parse(json['snapshot_date'] as String),
      value: parseToDouble(json['value']),
    );
  }

  Map<String, dynamic> toJson() => {
    'snapshot_date': snapshotDate.toIso8601String().split('T').first,
    'value': value,
  };
}
