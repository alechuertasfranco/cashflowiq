// lib/features/statements/data/statement_reconciler.dart
//
// Client-side reconciliation: cross each parsed statement line against the
// transactions already registered for the account+month, so the review screen
// can mark "ya registrado" vs "nuevo" and only import the new ones.

import 'package:cashflowiq/features/statements/data/statement_parser.dart';
import 'package:cashflowiq/shared/models/transaction.dart';

/// A parsed line plus its reconciliation state and the user's editable choices.
class ReconciledLine {
  final ParsedStatementLine line;

  /// True when a matching transaction already exists for this movement.
  final bool matched;

  /// Whether to include this line in the import (only meaningful when !matched).
  bool include;

  /// Category chosen by the user for a new line. **Required** before a new
  /// line can be imported (the parser can't infer it from the statement).
  String? categoryId;

  /// User correction of the parsed type (INCOME|EXPENSE). When the parser
  /// misclassifies a movement, changing this re-filters the category options.
  String? overrideType;

  ReconciledLine({
    required this.line,
    required this.matched,
  }) : include = !matched;

  /// Effective type: the user's correction if any, else the parsed type.
  String get type => overrideType ?? line.type;

  /// Direction from the statement itself: an abono (parsed INCOME) is money
  /// INTO the account; a cargo (parsed EXPENSE) is money OUT. This is fixed by
  /// the statement and does not change when the user re-labels the line as a
  /// transfer — it only decides which leg of a transfer the account gets.
  bool get isInflow => line.type == 'INCOME';
}

class StatementReconciler {
  /// Match parsed lines against existing transactions by **direction** (money
  /// in/out of the account) + amount (±0.01) + date within [dayTolerance] days.
  ///
  /// Matching on direction rather than on INCOME/EXPENSE/TRANSFER is deliberate:
  /// a statement inflow may already be registered as either an INCOME or a
  /// TRANSFER into the account (e.g. money moved from another own account), and
  /// both should reconcile as "ya registrado". Each existing transaction backs
  /// at most one parsed line (greedy, first-fit).
  List<ReconciledLine> reconcile(
    List<ParsedStatementLine> parsed,
    List<Transaction> existing,
    String accountId, {
    int dayTolerance = 3,
  }) {
    final used = <int>{};
    final result = <ReconciledLine>[];

    for (final line in parsed) {
      final lineInflow = line.type == 'INCOME';
      int matchIdx = -1;
      for (int i = 0; i < existing.length; i++) {
        if (used.contains(i)) continue;
        final tx = existing[i];
        final sameDir = _isInflow(tx, accountId) == lineInflow;
        final sameAmount = (tx.amount - line.amount).abs() < 0.01;
        final closeDate =
            tx.date.difference(line.date).inDays.abs() <= dayTolerance;
        if (sameDir && sameAmount && closeDate) {
          matchIdx = i;
          break;
        }
      }
      if (matchIdx >= 0) used.add(matchIdx);
      result.add(ReconciledLine(line: line, matched: matchIdx >= 0));
    }

    return result;
  }

  /// Whether [tx] moves money INTO [accountId] (vs out of it).
  bool _isInflow(Transaction tx, String accountId) {
    switch (tx.type) {
      case TransactionType.income:
        return true;
      case TransactionType.expense:
        return false;
      case TransactionType.transfer:
        // A transfer into the account credits it (to_account == this account).
        return tx.toAccountId == accountId;
    }
  }
}
