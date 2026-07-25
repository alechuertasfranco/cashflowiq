// lib/features/statements/data/statement_parser.dart
//
// On-device parser for bank "estado de cuenta" PDFs. Uses coordinate-aware
// text extraction (word bounds) to reconstruct table rows, because flat text
// extraction jumbles multi-column bank layouts (confirmed with real Interbank
// and BCP statements). Two bank strategies plus a generic fallback.
//
// Robustness notes baked in from real statements:
//   • BCP downloads carry a 5-byte "$BOP$" prefix before the "%PDF-" header.
//   • BCP statements are user-password protected → caller passes the password.
//   • Amount sign encodes the type in Interbank (+ income / − expense); BCP
//     uses separate CARGOS(debit=expense) / ABONOS(credit=income) columns.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// One movement parsed from a statement (already normalized).
class ParsedStatementLine {
  final DateTime date;
  final double amount; // always positive
  final String type; // INCOME | EXPENSE
  final String description;

  const ParsedStatementLine({
    required this.date,
    required this.amount,
    required this.type,
    required this.description,
  });
}

/// Result of parsing a statement PDF.
class StatementParseResult {
  final String bank; // 'interbank' | 'bcp' | 'generic'
  final List<ParsedStatementLine> lines;

  /// Footer totals when the statement exposes them (Interbank) — used to show
  /// a confidence check ("parsed sum vs statement total").
  final double? footerIncome;
  final double? footerExpense;

  /// Statement's opening and closing (final) balance for the period, when the
  /// statement exposes them. Used to reconcile against the app's monthly-balance
  /// snapshot for a closed month.
  final double? openingBalance;
  final double? finalBalance;

  const StatementParseResult({
    required this.bank,
    required this.lines,
    this.footerIncome,
    this.footerExpense,
    this.openingBalance,
    this.finalBalance,
  });

  double get parsedIncome =>
      lines.where((l) => l.type == 'INCOME').fold(0.0, (s, l) => s + l.amount);
  double get parsedExpense =>
      lines.where((l) => l.type == 'EXPENSE').fold(0.0, (s, l) => s + l.amount);
}

/// Thrown when the PDF is encrypted and no/invalid password was supplied.
class StatementPasswordException implements Exception {
  final bool invalid; // true → a password was given but rejected
  const StatementPasswordException({this.invalid = false});
}

// ─────────────────────────────────────────────────────────────────────────
// Internal positioned-word model
// ─────────────────────────────────────────────────────────────────────────

class _Word {
  final int page;
  final double x; // left
  final double right;
  final double y; // top
  final String text;
  _Word(this.page, this.x, this.right, this.y, this.text);
  double get cx => (x + right) / 2;
}

class _Row {
  final int page;
  final double y;
  final List<_Word> words;
  _Row(this.page, this.y, this.words);
  String get text => words.map((w) => w.text).join(' ');
}

// ─────────────────────────────────────────────────────────────────────────
// Orchestrator
// ─────────────────────────────────────────────────────────────────────────

class StatementParser {
  /// Strip the leading "$BOP$" (or any junk) that some banks prepend before
  /// the real "%PDF-" header. Returns the bytes starting at "%PDF-".
  static Uint8List stripPdfPrefix(Uint8List bytes) {
    // "%PDF-" = 0x25 0x50 0x44 0x46 0x2D
    const marker = [0x25, 0x50, 0x44, 0x46, 0x2D];
    final limit = bytes.length - marker.length;
    for (int i = 0; i <= limit && i < 64; i++) {
      var match = true;
      for (int j = 0; j < marker.length; j++) {
        if (bytes[i + j] != marker[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        return i == 0 ? bytes : Uint8List.sublistView(bytes, i);
      }
    }
    return bytes;
  }

  Future<StatementParseResult> parseFile(File file, {String? password}) async {
    final raw = await file.readAsBytes();
    final bytes = stripPdfPrefix(raw);

    PdfDocument document;
    try {
      document = (password != null && password.isNotEmpty)
          ? PdfDocument(inputBytes: bytes, password: password)
          : PdfDocument(inputBytes: bytes);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') || msg.contains('encrypt')) {
        throw StatementPasswordException(
          invalid: password != null && password.isNotEmpty,
        );
      }
      rethrow;
    }

    try {
      final extractor = PdfTextExtractor(document);
      final fullText = extractor.extractText();
      final rows = _extractRows(extractor, document.pages.count);
      final bank = _detectBank(fullText);
      switch (bank) {
        case 'interbank':
          return _InterbankParser().parse(rows);
        case 'bcp':
          return _BcpParser().parse(rows, fullText);
        default:
          return _GenericParser().parse(rows);
      }
    } finally {
      document.dispose();
    }
  }

  String _detectBank(String text) {
    final t = text.toLowerCase();
    if (t.contains('interbank') || t.contains('cuenta simple')) return 'interbank';
    if (t.contains('viabcp') ||
        t.contains('codigo de cuenta') ||
        t.contains('bcp')) {
      return 'bcp';
    }
    return 'generic';
  }

  /// Group extracted words into visual rows by Y band (per page). More robust
  /// than trusting the extractor's own line grouping for multi-column tables.
  List<_Row> _extractRows(PdfTextExtractor extractor, int pageCount) {
    final words = <_Word>[];
    final lines = extractor.extractTextLines();
    for (final TextLine line in lines) {
      for (final TextWord w in line.wordCollection) {
        final Rect b = w.bounds;
        final text = w.text.trim();
        if (text.isEmpty) continue;
        words.add(_Word(line.pageIndex, b.left, b.right, b.top, text));
      }
    }

    words.sort((a, b) {
      if (a.page != b.page) return a.page.compareTo(b.page);
      if ((a.y - b.y).abs() > 2.5) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    final rows = <_Row>[];
    for (final w in words) {
      if (rows.isNotEmpty &&
          rows.last.page == w.page &&
          (rows.last.y - w.y).abs() <= 2.5) {
        rows.last.words.add(w);
      } else {
        rows.add(_Row(w.page, w.y, [w]));
      }
    }
    for (final r in rows) {
      r.words.sort((a, b) => a.x.compareTo(b.x));
    }
    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared parsing helpers
// ─────────────────────────────────────────────────────────────────────────

double? _num(String token) {
  // Accept "1,919.17", "50.00", "298", "-99.08", "+50.00".
  final cleaned = token.replaceAll(RegExp(r'[+\-]'), '').replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

const _esMonths = {
  'ENE': 1, 'FEB': 2, 'MAR': 3, 'ABR': 4, 'MAY': 5, 'JUN': 6,
  'JUL': 7, 'AGO': 8, 'SET': 9, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DIC': 12,
};

// ─────────────────────────────────────────────────────────────────────────
// Interbank — "Cuenta Simple Soles"
//   Row: DD/MM/YYYY  <concepto...>  <±monto>  <saldo>
//   Sign of the movement amount encodes the type (+ income / − expense).
// ─────────────────────────────────────────────────────────────────────────

class _InterbankParser {
  static final _dateRe = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
  static final _signedRe = RegExp(r'^([+\-])(\d[\d,]*\.\d{2})$');
  static final _footerRe = RegExp(
    r'SALDO CONTABLE AL.*?\+([\d,]+\.\d{2}).*?-([\d,]+\.\d{2})\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );
  static final _openingRe = RegExp(
    r'EMPEZASTE.*?([\d,]+\.\d{2})',
    caseSensitive: false,
  );

  StatementParseResult parse(List<_Row> rows) {
    final lines = <ParsedStatementLine>[];
    double? footerIncome;
    double? footerExpense;
    double? openingBalance;
    double? finalBalance;

    for (final row in rows) {
      final upper = row.text.toUpperCase();
      if (upper.contains('SALDO CONTABLE AL')) {
        final m = _footerRe.firstMatch(row.text);
        if (m != null) {
          // First footer wins — a PDF may concatenate several statements.
          footerIncome ??= _num(m.group(1)!);
          footerExpense ??= _num(m.group(2)!);
          finalBalance ??= _num(m.group(3)!);
        }
        continue;
      }
      if (upper.contains('EMPEZASTE')) {
        final m = _openingRe.firstMatch(row.text);
        if (m != null) openingBalance ??= _num(m.group(1)!);
        continue;
      }
      if (upper.contains('DETALLE DE MOVIMIENTOS') ||
          upper.contains('SALDO CONTABLE') && !upper.contains('/')) {
        continue;
      }

      final tokens = row.words.map((w) => w.text).toList();
      if (tokens.isEmpty) continue;
      final dm = _dateRe.firstMatch(tokens.first);
      if (dm == null) continue;

      final date = DateTime(
        int.parse(dm.group(3)!),
        int.parse(dm.group(2)!),
        int.parse(dm.group(1)!),
      );

      // Find the signed movement amount; description is everything between the
      // date and that token.
      int amountIdx = -1;
      String? sign;
      double? amount;
      for (int i = 1; i < tokens.length; i++) {
        final sm = _signedRe.firstMatch(tokens[i]);
        if (sm != null) {
          amountIdx = i;
          sign = sm.group(1);
          amount = _num(sm.group(2)!);
          break;
        }
      }
      if (amountIdx == -1 || amount == null) continue;

      final description = tokens.sublist(1, amountIdx).join(' ').trim();
      lines.add(ParsedStatementLine(
        date: date,
        amount: amount,
        type: sign == '-' ? 'EXPENSE' : 'INCOME',
        description: description.isEmpty ? 'Movimiento' : description,
      ));
    }

    return StatementParseResult(
      bank: 'interbank',
      lines: lines,
      footerIncome: footerIncome,
      footerExpense: footerExpense,
      openingBalance: openingBalance,
      finalBalance: finalBalance,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// BCP — "Estado de Cuenta de Ahorros"
//   Columns: FECHA PROC(DDMMM) · FECHA VALOR · DESCRIPCION · CARGOS/DEBE · ABONOS/HABER · saldo
//   Debit(CARGOS) → EXPENSE, Credit(ABONOS) → INCOME. Year from the period line.
//   Best-effort: assigns numeric tokens to the cargo/abono column by nearest
//   X reference derived from the header row. Needs live calibration.
// ─────────────────────────────────────────────────────────────────────────

class _BcpParser {
  static final _dateRe = RegExp(r'^(\d{2})([A-Z]{3})$'); // 02JUN
  static final _numRe = RegExp(r'^\d[\d,]*\.\d{2}$');
  static final _periodRe = RegExp(
    r'DEL\s+\d{2}/\d{2}/(\d{2})\s+AL\s+\d{2}/\d{2}/(\d{2})',
    caseSensitive: false,
  );

  StatementParseResult parse(List<_Row> rows, String fullText) {
    // Year from the period line ("DEL 01/06/26 AL 30/06/26").
    int year = DateTime.now().year;
    final pm = _periodRe.firstMatch(fullText);
    if (pm != null) {
      year = 2000 + int.parse(pm.group(2)!);
    }

    // Locate column references from the header row.
    double? cargoRef;
    double? abonoRef;
    for (final row in rows) {
      final u = row.text.toUpperCase();
      if (u.contains('DESCRIPCION') &&
          (u.contains('CARGOS') || u.contains('ABONOS'))) {
        for (final w in row.words) {
          final t = w.text.toUpperCase();
          if (t.contains('CARGOS') || t.contains('DEBE')) cargoRef = w.cx;
          if (t.contains('ABONOS') || t.contains('HABER')) abonoRef = w.cx;
        }
        break;
      }
    }

    final lines = <ParsedStatementLine>[];
    double? openingBalance;
    double? finalBalance;
    bool afterTotal = false;
    bool stop = false;
    for (final row in rows) {
      if (stop) break;
      final u = row.text.toUpperCase();
      if (u.contains('MENSAJE AL CLIENTE')) {
        stop = true;
        continue;
      }
      if (u.contains('SALDO ANTERIOR')) {
        openingBalance ??= _firstNum(row);
        continue;
      }
      if (u.contains('TOTAL MOVIMIENTO')) {
        // Everything past here is the closing block; the final SALDO value is
        // the first standalone number that follows.
        afterTotal = true;
        continue;
      }
      if (afterTotal) {
        finalBalance ??= _firstNum(row);
        continue;
      }
      if (u.startsWith('SALDO') || u.contains('DESCRIPCION')) {
        continue;
      }

      final tokens = row.words;
      if (tokens.isEmpty) continue;
      final dm = _dateRe.firstMatch(tokens.first.text.toUpperCase());
      if (dm == null) continue;
      final month = _esMonths[dm.group(2)!];
      if (month == null) continue;
      final date = DateTime(year, month, int.parse(dm.group(1)!));

      // Numeric tokens in the row, tagged with their X center.
      final nums = <_Word>[];
      final descWords = <String>[];
      for (int i = 1; i < tokens.length; i++) {
        final w = tokens[i];
        if (_numRe.hasMatch(w.text)) {
          nums.add(w);
        } else if (_dateRe.hasMatch(w.text.toUpperCase()) || w.text == '*') {
          // second date column / ITF flag — skip from description
        } else {
          descWords.add(w.text);
        }
      }
      if (nums.isEmpty) continue;

      // Decide movement column. With column refs, classify each numeric token
      // as cargo/abono/saldo by nearest reference; pick the movement value.
      double? cargo;
      double? abono;
      if (cargoRef != null && abonoRef != null) {
        for (final n in nums) {
          final dc = (n.cx - cargoRef).abs();
          final da = (n.cx - abonoRef).abs();
          // saldo sits to the right of abono; ignore tokens well past it.
          if (n.cx > abonoRef + (abonoRef - cargoRef)) continue;
          final v = _num(n.text);
          if (v == null) continue;
          if (dc <= da) {
            cargo ??= v;
          } else {
            abono ??= v;
          }
        }
      } else {
        // No column refs → assume the first numeric is the movement, last is
        // the balance. Type guessed from keywords (weak; user reviews).
        final v = _num(nums.first.text);
        if (v != null) {
          if (_looksIncome(u)) {
            abono = v;
          } else {
            cargo = v;
          }
        }
      }

      final desc = descWords.join(' ').trim();
      if (abono != null) {
        lines.add(ParsedStatementLine(
          date: date,
          amount: abono,
          type: 'INCOME',
          description: desc.isEmpty ? 'Abono' : desc,
        ));
      } else if (cargo != null) {
        lines.add(ParsedStatementLine(
          date: date,
          amount: cargo,
          type: 'EXPENSE',
          description: desc.isEmpty ? 'Cargo' : desc,
        ));
      }
    }

    return StatementParseResult(
      bank: 'bcp',
      lines: lines,
      openingBalance: openingBalance,
      finalBalance: finalBalance,
    );
  }

  /// First token in the row that looks like a money amount (e.g. "350.00").
  double? _firstNum(_Row row) {
    for (final w in row.words) {
      if (_numRe.hasMatch(w.text)) return _num(w.text);
    }
    return null;
  }

  bool _looksIncome(String upper) {
    return upper.contains('YAPE') ||
        upper.contains('PLIN') ||
        upper.contains('PLANILLA') ||
        upper.contains('ABONO') ||
        upper.contains('DEPOSITO') ||
        upper.contains('TRANSF');
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Generic best-effort fallback
// ─────────────────────────────────────────────────────────────────────────

class _GenericParser {
  static final _dateRe = RegExp(r'(\d{2})[/\-](\d{2})[/\-](\d{2,4})');
  static final _amountRe = RegExp(r'([+\-]?)(\d[\d,]*\.\d{2})');

  StatementParseResult parse(List<_Row> rows) {
    final lines = <ParsedStatementLine>[];
    for (final row in rows) {
      final text = row.text;
      final dm = _dateRe.firstMatch(text);
      final am = _amountRe.firstMatch(text);
      if (dm == null || am == null) continue;
      final amount = _num(am.group(2)!);
      if (amount == null) continue;
      var y = int.parse(dm.group(3)!);
      if (y < 100) y += 2000;
      final date = DateTime(y, int.parse(dm.group(2)!), int.parse(dm.group(1)!));
      lines.add(ParsedStatementLine(
        date: date,
        amount: amount,
        type: am.group(1) == '-' ? 'EXPENSE' : 'INCOME',
        description: text.replaceAll(dm.group(0)!, '').replaceAll(am.group(0)!, '').trim(),
      ));
    }
    return StatementParseResult(bank: 'generic', lines: lines);
  }
}
