// lib/features/statements/presentation/statement_import_controller.dart

import 'dart:io';

import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/statements/data/statement_import_service.dart';
import 'package:cashflowiq/features/statements/data/statement_parser.dart';
import 'package:cashflowiq/features/statements/data/statement_reconciler.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/statement_import.dart';
import 'package:flutter/foundation.dart' hide Category;

/// Steps of the statement-import flow.
enum ImportStep { pickAccount, pickFile, review }

class StatementImportController extends ChangeNotifier {
  final _accountService = BankAccountService();
  final _categoryService = CategoryService();
  final _transactionService = TransactionService();
  final _importService = StatementImportService();
  final _parser = StatementParser();
  final _reconciler = StatementReconciler();

  // ── Step state ──────────────────────────────────────────────────────────
  ImportStep step = ImportStep.pickAccount;

  // ── Sources ─────────────────────────────────────────────────────────────
  List<BankAccount> accounts = [];
  List<Category> categories = [];
  bool loadingSources = true;

  BankAccount? selectedAccount;
  int year = DateTime.now().year;
  int month = DateTime.now().month;

  // ── Parse / review state ────────────────────────────────────────────────
  bool parsing = false;
  String? parseError;
  String? fileName;
  StatementParseResult? result;
  List<ReconciledLine> reconciled = [];

  // Monthly-balance reconciliation (only meaningful for a closed month).
  bool monthClosed = false;
  double? snapshotFinalBalance;

  bool saving = false;

  // ── Derived ─────────────────────────────────────────────────────────────
  List<ReconciledLine> get newLines =>
      reconciled.where((r) => !r.matched).toList();
  List<ReconciledLine> get matchedLines =>
      reconciled.where((r) => r.matched).toList();
  int get selectedCount => newLines.where((r) => r.include).length;

  /// Included INCOME/EXPENSE lines still missing a category — must be empty to
  /// import. Transfers are not categorized, so they never block the import.
  List<ReconciledLine> get pendingCategory => newLines
      .where((r) => r.include && r.type != 'TRANSFER' && r.categoryId == null)
      .toList();

  bool get readyToImport => selectedCount > 0 && pendingCategory.isEmpty;

  double get _includedNewDelta => newLines.where((r) => r.include).fold(
        0.0,
        (s, r) => s + (r.isInflow ? r.line.amount : -r.line.amount),
      );

  /// Projected account balance for the month after importing the selected new
  /// lines: the closed-month snapshot plus the net of the imported movements.
  /// Null when the month isn't closed (nothing to reconcile against).
  double? get projectedFinalBalance =>
      (monthClosed && snapshotFinalBalance != null)
          ? snapshotFinalBalance! + _includedNewDelta
          : null;

  double? get statementFinalBalance => result?.finalBalance;

  /// Whether the projected post-import balance agrees with the statement's
  /// closing balance. Null when it can't be checked (open month, or the
  /// statement didn't expose a closing balance).
  bool? get balanceReconciles {
    final projected = projectedFinalBalance;
    final statement = statementFinalBalance;
    if (projected == null || statement == null) return null;
    return (projected - statement).abs() < 0.01;
  }

  List<Category> categoriesFor(String type) => categories
      .where((c) => c.type.toApi() == type && c.parentId == null)
      .toList();

  Future<void> loadSources() async {
    loadingSources = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _accountService.getAccounts(),
        _categoryService.getCategoriesWithChildren(),
      ]);
      accounts = results[0] as List<BankAccount>;
      categories = results[1] as List<Category>;
    } catch (e) {
      debugPrint('statement import loadSources error: $e');
    } finally {
      loadingSources = false;
      notifyListeners();
    }
  }

  void selectAccount(BankAccount? account) {
    selectedAccount = account;
    notifyListeners();
  }

  void setPeriod({int? year, int? month}) {
    if (year != null) this.year = year;
    if (month != null) this.month = month;
    notifyListeners();
  }

  bool get canProceedFromAccount => selectedAccount != null;

  void goToPickFile() {
    if (!canProceedFromAccount) return;
    step = ImportStep.pickFile;
    notifyListeners();
  }

  void back() {
    if (step == ImportStep.review) {
      step = ImportStep.pickFile;
    } else if (step == ImportStep.pickFile) {
      step = ImportStep.pickAccount;
    }
    notifyListeners();
  }

  /// Parse the chosen PDF and reconcile. Rethrows [StatementPasswordException]
  /// so the screen can prompt for the password and retry.
  Future<void> parseAndReconcile(File file, {String? password}) async {
    parsing = true;
    parseError = null;
    fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'estado.pdf';
    notifyListeners();

    try {
      final parsed = await _parser.parseFile(file, password: password);

      // Scope to the selected period: a single "estado de cuenta" is one month,
      // and this also guards against multi-statement PDFs bleeding other months
      // (e.g. concatenated samples) into the import.
      final monthLines = parsed.lines
          .where((l) => l.date.year == year && l.date.month == month)
          .toList();
      final scoped = StatementParseResult(
        bank: parsed.bank,
        lines: monthLines,
        footerIncome: parsed.footerIncome,
        footerExpense: parsed.footerExpense,
      );

      // Load existing transactions for the account + month to reconcile.
      final from = DateTime(year, month, 1);
      final to = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
      final existing = await _transactionService.getTransactions(
        accountId: selectedAccount!.id,
        fromDate: _isoDate(from),
        toDate: _isoDate(to),
      );

      // Closed-month snapshot to reconcile the statement's closing balance.
      try {
        final mb = await _importService.getMonthlyBalance(
          accountId: selectedAccount!.id,
          year: year,
          month: month,
        );
        monthClosed = mb.closed;
        snapshotFinalBalance = mb.finalBalance;
      } catch (e) {
        debugPrint('monthly-balance fetch error: $e');
        monthClosed = false;
        snapshotFinalBalance = null;
      }

      result = scoped;
      reconciled =
          _reconciler.reconcile(scoped.lines, existing, selectedAccount!.id);
      step = ImportStep.review;
    } on StatementPasswordException {
      rethrow;
    } catch (e) {
      debugPrint('statement parse error: $e');
      parseError = 'No se pudo leer el estado de cuenta. Verifica el archivo.';
    } finally {
      parsing = false;
      notifyListeners();
    }
  }

  void toggleInclude(ReconciledLine line) {
    line.include = !line.include;
    notifyListeners();
  }

  void setCategory(ReconciledLine line, String? categoryId) {
    line.categoryId = categoryId;
    notifyListeners();
  }

  /// Correct a misclassified line's type. Clears the category because the
  /// available options change with the type.
  void setType(ReconciledLine line, String type) {
    if (line.type == type) return;
    line.overrideType = type;
    line.categoryId = null;
    notifyListeners();
  }

  /// POST the selected new lines as one import batch. Returns the created
  /// batch, or null on failure.
  Future<StatementImportBatch?> submit() async {
    if (selectedAccount == null) return null;
    final toImport = newLines.where((r) => r.include).toList();
    if (toImport.isEmpty) return null;

    saving = true;
    notifyListeners();
    try {
      final items = toImport.map((r) {
        final isTransfer = r.type == 'TRANSFER';
        return <String, dynamic>{
          'date': r.line.date.toIso8601String(),
          'amount': r.line.amount,
          'type': r.type,
          'is_inflow': r.isInflow,
          'description': r.line.description,
          'category_id': (!isTransfer && r.categoryId != null)
              ? int.tryParse(r.categoryId!)
              : null,
        };
      }).toList();

      final batch = await _importService.create(
        accountId: selectedAccount!.id,
        year: year,
        month: month,
        filename: fileName ?? 'estado.pdf',
        bank: result?.bank,
        items: items,
      );
      return batch;
    } catch (e) {
      debugPrint('statement import submit error: $e');
      return null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
