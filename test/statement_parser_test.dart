// Local validation of the on-device statement parser against real bank PDFs.
//
// Runs the pure-Dart syncfusion parser (no emulator needed) on the reference
// statements the user provided. Guards on file existence so it is skipped when
// the sample PDFs aren't present.
//
//   flutter test test/statement_parser_test.dart

import 'dart:io';

import 'package:cashflowiq/features/statements/data/statement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _downloads = r'C:\Users\usuario\Downloads';

double _sum(Iterable<ParsedStatementLine> lines, String type) =>
    lines.where((l) => l.type == type).fold(0.0, (s, l) => s + l.amount);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Interbank — June 2026 movements total exactly', () async {
    final file = File('$_downloads\\eecc-1.pdf');
    if (!file.existsSync()) {
      // ignore: avoid_print
      print('SKIP: ${file.path} not found');
      return;
    }

    final result = await StatementParser().parseFile(file);
    expect(result.bank, 'interbank');

    // eecc-1.pdf concatenates two sample statements; the app scopes to the
    // selected period, so validate the June 2026 slice here.
    final june =
        result.lines.where((l) => l.date.year == 2026 && l.date.month == 6);
    expect(june.length, 18);
    expect(_sum(june, 'INCOME'), closeTo(1919.17, 0.01));
    expect(_sum(june, 'EXPENSE'), closeTo(1957.00, 0.01));

    // Statement balances: opening 37.83, final 0.00.
    expect(result.openingBalance, closeTo(37.83, 0.01));
    expect(result.finalBalance, closeTo(0.00, 0.01));
    // Internal consistency: opening + income - expense == final.
    expect(
      result.openingBalance! + 1919.17 - 1957.00,
      closeTo(result.finalBalance!, 0.01),
    );
  });

  test('BCP — password + \$BOP\$ prefix, totals match TOTAL MOVIMIENTO',
      () async {
    final file = File('$_downloads\\EECC062026_14187827.PDF');
    if (!file.existsSync()) {
      // ignore: avoid_print
      print('SKIP: ${file.path} not found');
      return;
    }

    final result =
        await StatementParser().parseFile(file, password: '70654418');
    expect(result.bank, 'bcp');

    final june =
        result.lines.where((l) => l.date.year == 2026 && l.date.month == 6);
    // Statement footer: CARGOS 2,031.36 / ABONOS 2,381.36.
    expect(_sum(june, 'EXPENSE'), closeTo(2031.36, 0.01));
    expect(_sum(june, 'INCOME'), closeTo(2381.36, 0.01));

    // Balances: opening (SALDO ANTERIOR) 0.00, final (SALDO) 350.00.
    // 0.00 + 2381.36 - 2031.36 == 350.00.
    expect(result.finalBalance, closeTo(350.00, 0.01));
    expect(result.openingBalance, closeTo(0.00, 0.01));
  });
}
