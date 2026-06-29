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
    return VoucherResult(
      amount: _extractSoles(text),
      description: _extractYapeConcept(lines),
      date: _extractSpanishDate(text),
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

    return VoucherResult(
      amount: _extractSoles(text),
      description: description,
      date: _extractSpanishDate(text),
      recipient: _lineAfterAmount(lines),
      currencyCode: 'PEN',
    );
  }

  // ─────────────────────────────────────────────
  // Generic: best-effort extraction for any receipt
  // ─────────────────────────────────────────────
  VoucherResult _parseGeneric(String text) {
    final lines = _lines(text);

    double? amount = _extractSoles(text);
    String? currencyCode = amount != null ? 'PEN' : null;

    if (amount == null) {
      final m = RegExp(r'\$\s*(\d+(?:[.,]\d{1,2})?)').firstMatch(text);
      if (m != null) {
        amount = double.tryParse(m.group(1)!.replaceAll(',', '.'));
        currencyCode = 'USD';
      }
    }

    final date = _extractSpanishDate(text) ?? _extractIsoDate(text);

    final skipPattern = RegExp(r'^S/|^\$|\d+[.,]\d{2}$|\d{1,2}[\s/\-]\w+[\s/\-]\d{4}|^\d+$');
    final description = lines.firstWhere(
      (l) => l.length > 3 && !skipPattern.hasMatch(l),
      orElse: () => '',
    );

    return VoucherResult(
      amount: amount,
      description: description.isEmpty ? null : description,
      date: date,
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
