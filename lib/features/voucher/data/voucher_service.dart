// lib/features/voucher/data/voucher_service.dart

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class VoucherResult {
  final double? amount;
  final String? description;
  final String? date;
  final String? recipient;
  final String? currencyCode;

  const VoucherResult({
    this.amount,
    this.description,
    this.date,
    this.recipient,
    this.currencyCode,
  });
}

class VoucherService {
  static const _monthMap = {
    'ene': '01', 'feb': '02', 'mar': '03', 'abr': '04',
    'may': '05', 'jun': '06', 'jul': '07', 'ago': '08',
    'sep': '09', 'oct': '10', 'nov': '11', 'dic': '12',
  };

  Future<VoucherResult> parseVoucher({
    required File imageFile,
    required String serviceType,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognized = await recognizer.processImage(inputImage);
    await recognizer.close();

    final text = recognized.text;

    switch (serviceType) {
      case 'yape':
        return _parseYape(text);
      case 'plin':
        return _parsePlin(text);
      default:
        return _parseGeneric(text);
    }
  }

  // ─────────────────────────────────────────────
  // Yape
  // Typical structure:
  //   ¡Yapeaste!
  //   S/ 6
  //   Josue Vel*
  //   28 jun. 2026  |  03:09 p. m.
  //   Arbitraje            ← concept in highlighted box
  //   CÓDIGO DE SEGURIDAD  4  3  7
  // ─────────────────────────────────────────────
  VoucherResult _parseYape(String text) {
    final lines = _lines(text);
    final time = _extractTime(text) ?? _nowTime();
    return VoucherResult(
      amount: _extractSoles(text),
      description: _extractYapeConcept(lines),
      date: _withTime(_extractSpanishDate(text), time),
      recipient: _lineAfterAmount(lines),
      currencyCode: 'PEN',
    );
  }

  // ─────────────────────────────────────────────
  // Plin — similar structure, may label concept as "Concepto" or "Motivo"
  // ─────────────────────────────────────────────
  VoucherResult _parsePlin(String text) {
    final lines = _lines(text);

    String? description;
    final conceptIdx = lines.indexWhere(
      (l) => l.toLowerCase().contains('concepto') || l.toLowerCase().contains('motivo'),
    );
    if (conceptIdx != -1 && conceptIdx + 1 < lines.length) {
      description = lines[conceptIdx + 1];
    }
    description ??= _extractYapeConcept(lines);
    final time = _extractTime(text) ?? _nowTime();

    return VoucherResult(
      amount: _extractSoles(text),
      description: description,
      date: _withTime(_extractSpanishDate(text), time),
      recipient: _lineAfterAmount(lines),
      currencyCode: 'PEN',
    );
  }

  // ─────────────────────────────────────────────
  // Generic: best-effort extraction for any receipt
  //
  // Also covers bank/card transaction confirmations (e.g. Google Pay),
  // which write amounts as "PEN51.80" (code glued to the number, no
  // symbol) and dates in English with no year, e.g.
  // "Completed . Tuesday, Jun 30 at 7:49 PM".
  // ─────────────────────────────────────────────
  VoucherResult _parseGeneric(String text) {
    final lines = _lines(text);

    final amountMatch = _genericAmountRegex.firstMatch(text);
    double? amount;
    String? currencyCode;
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(2)!.replaceAll(',', '.'));
      final token = amountMatch.group(1)!;
      currencyCode = token == 'S/' ? 'PEN' : (token == r'$' ? 'USD' : token);
    }

    final date = _extractSpanishDate(text) ??
        _extractIsoDate(text) ??
        _extractEnglishDate(text);
    final time = _extractTime(text) ?? _nowTime();

    final skipPattern = RegExp(r'^S/|^\$|\d+[.,]\d{2}$|\d{1,2}[\s/\-]\w+[\s/\-]\d{4}|^\d+$');
    String? description =
        _lineBeforeAmountMatch(lines, amountMatch?.group(0));
    description ??= lines.firstWhere(
      (l) => l.length > 3 && !skipPattern.hasMatch(l),
      orElse: () => '',
    );

    return VoucherResult(
      amount: amount,
      description: description.isEmpty ? null : description,
      date: _withTime(date, time),
      recipient: null,
      currencyCode: currencyCode,
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  List<String> _lines(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  static final _solesRegex = RegExp(r'S/\s*(\d+(?:[.,]\d{1,2})?)');

  double? _extractSoles(String text) {
    final m = _solesRegex.firstMatch(text);
    return m != null ? double.tryParse(m.group(1)!.replaceAll(',', '.')) : null;
  }

  String? _lineAfterAmount(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (_solesRegex.hasMatch(lines[i]) && i + 1 < lines.length) {
        return lines[i + 1];
      }
    }
    return null;
  }

  // Matches "S/ 6", "$ 12.34" and bank-style codes glued to the amount
  // like "PEN51.80" or "USD12.00".
  static final _genericAmountRegex = RegExp(
    r'(S/|\$|PEN|USD|EUR|GBP|MXN|ARS|CLP|COP|BRL|CAD|JPY)\s*(\d+(?:[.,]\d{1,3})?)',
  );

  // Bank/card confirmations often place the merchant name on the line
  // right above the amount, e.g. "VD+*CARBON DORADO" \n "PEN51.80".
  String? _lineBeforeAmountMatch(List<String> lines, String? matchedText) {
    if (matchedText == null) return null;
    final idx = lines.indexWhere((l) => l.contains(matchedText));
    if (idx <= 0) return null;
    final candidate = lines[idx - 1];
    if (candidate.length <= 3 || RegExp(r'^\d').hasMatch(candidate)) return null;
    return candidate;
  }

  static final _spanishDateRegex = RegExp(
    r'(\d{1,2})\s+(ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic)\.?\s+(\d{4})',
    caseSensitive: false,
  );

  String? _extractSpanishDate(String text) {
    final m = _spanishDateRegex.firstMatch(text);
    if (m == null) return null;
    final day = m.group(1)!.padLeft(2, '0');
    final month = _monthMap[m.group(2)!.toLowerCase()] ?? '01';
    final year = m.group(3)!;
    return '$year-$month-$day';
  }

  String? _extractIsoDate(String text) {
    final m = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(text);
    return m?.group(0);
  }

  // Matches "03:09 p. m.", "12:33 a. m.", "7:49 PM" — covers both the
  // Spanish "a. m./p. m." style used by Yape/Plin and plain English AM/PM.
  static final _timeRegex = RegExp(
    r'(\d{1,2}):(\d{2})\s*([ap])\.?\s*m\.?',
    caseSensitive: false,
  );

  String? _extractTime(String text) {
    final m = _timeRegex.firstMatch(text);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = m.group(2)!;
    final isPm = m.group(3)!.toLowerCase() == 'p';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  // Voucher OCR only ever yields a date-only string ("2026-07-09"), which
  // DateTime.parse silently interprets as midnight — losing the receipt's
  // actual time. Append the extracted time (or fall back to now's time) so
  // the resulting transaction date isn't always stamped at 00:00.
  String? _withTime(String? date, String time) => date == null ? null : '${date}T$time';

  // Fallback when the receipt's time can't be OCR'd — better to stamp the
  // moment the voucher was scanned than to silently fall back to midnight.
  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  static const _englishMonthMap = {
    'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
    'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
    'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
  };

  // Bank confirmations often show an English month + day with no year,
  // e.g. "Completed . Tuesday, Jun 30 at 7:49 PM" — assume the current year.
  static final _englishDateRegex = RegExp(
    r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\.?\s+(\d{1,2})\b',
    caseSensitive: false,
  );

  String? _extractEnglishDate(String text) {
    final m = _englishDateRegex.firstMatch(text);
    if (m == null) return null;
    final month = _englishMonthMap[m.group(1)!.toLowerCase()] ?? '01';
    final day = m.group(2)!.padLeft(2, '0');
    final year = DateTime.now().year.toString();
    return '$year-$month-$day';
  }

  // Concept for Yape: lines between the date line and "CÓDIGO DE SEGURIDAD",
  // filtering out time strings, pipe separators, and bare digit sequences.
  String? _extractYapeConcept(List<String> lines) {
    final timeRegex = RegExp(r'\d{1,2}:\d{2}');

    int dateIdx = -1;
    int securityIdx = -1;
    for (int i = 0; i < lines.length; i++) {
      if (dateIdx == -1 && _spanishDateRegex.hasMatch(lines[i])) dateIdx = i;
      if (securityIdx == -1 && lines[i].toLowerCase().contains('código')) securityIdx = i;
    }

    if (dateIdx == -1 || securityIdx <= dateIdx + 1) return null;

    final candidate = lines
        .sublist(dateIdx + 1, securityIdx)
        .where((l) => !timeRegex.hasMatch(l))
        .where((l) => l != '|' && l != 'l' && l != 'I')
        .where((l) => !RegExp(r'^[\d\s]+$').hasMatch(l))
        .join(' ')
        .trim();

    return candidate.isEmpty ? null : candidate;
  }
}
