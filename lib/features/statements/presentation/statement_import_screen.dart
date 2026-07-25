// lib/features/statements/presentation/statement_import_screen.dart

import 'dart:io';

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
import 'package:cashflowiq/core/widgets/app_dropdown_field.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/features/statements/data/statement_parser.dart';
import 'package:cashflowiq/features/statements/data/statement_reconciler.dart';
import 'package:cashflowiq/features/statements/presentation/statement_import_controller.dart';
import 'package:cashflowiq/features/statements/presentation/statement_imports_history_screen.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

const _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class StatementImportScreen extends StatefulWidget {
  const StatementImportScreen({super.key});

  @override
  State<StatementImportScreen> createState() => _StatementImportScreenState();
}

class _StatementImportScreenState extends State<StatementImportScreen> {
  final controller = StatementImportController();

  @override
  void initState() {
    super.initState();
    controller.loadSources();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndParse() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = res?.files.single.path;
    if (path == null) return;
    await _parse(File(path));
  }

  Future<void> _parse(File file, {String? password}) async {
    try {
      await controller.parseAndReconcile(file, password: password);
    } on StatementPasswordException catch (e) {
      if (!mounted) return;
      final pwd = await _askPassword(invalid: e.invalid);
      if (pwd == null || pwd.isEmpty) return;
      await _parse(file, password: pwd);
    }
  }

  Future<String?> _askPassword({bool invalid = false}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PDF protegido', style: context.heading4()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invalid
                  ? 'La contraseña es incorrecta. Inténtalo de nuevo.'
                  : 'Este estado de cuenta requiere una contraseña para abrirse.',
              style: context.textBody1(color: context.colorTextSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Contraseña'),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Abrir',
                  onPressed: () => Navigator.of(context).pop(ctrl.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Guard: for a closed month, the statement's closing balance must agree
    // with the app's records after importing. Warn before finalizing if not.
    if (controller.monthClosed && controller.balanceReconciles == false) {
      final symbol = controller.selectedAccount?.currency.symbol ?? '';
      final statement = controller.statementFinalBalance ?? 0;
      final projected = controller.projectedFinalBalance ?? 0;
      final proceed = await showAppConfirmDialog(
        context,
        title: 'El saldo no cuadra',
        message:
            'Tras importar, el saldo del mes ($symbol${projected.toStringAsFixed(2)}) '
            'no coincide con el cierre del estado de cuenta ($symbol${statement.toStringAsFixed(2)}). '
            'Puede que falten o sobren movimientos, o que alguno esté mal clasificado. '
            '¿Importar de todas formas?',
        confirmText: 'Importar igual',
        isDestructive: true,
      );
      if (!proceed) return;
    }

    final batch = await controller.submit();
    if (!mounted) return;
    if (batch != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se importaron ${batch.importedCount} movimientos')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo importar el estado de cuenta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(
        title: 'Importar estado de cuenta',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (controller.step == ImportStep.pickAccount) {
              Navigator.pop(context);
            } else {
              controller.back();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Importaciones',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StatementImportsHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loadingSources) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonListLoader(itemCount: 4, itemHeight: 64),
              );
            }
            switch (controller.step) {
              case ImportStep.pickAccount:
                return _AccountStep(controller: controller);
              case ImportStep.pickFile:
                return _FileStep(
                  controller: controller,
                  onPick: _pickAndParse,
                );
              case ImportStep.review:
                return _ReviewStep(controller: controller, onSubmit: _submit);
            }
          },
        ),
      ),
    );
  }
}

// ── Step 1: account + month ───────────────────────────────────────────────

class _AccountStep extends StatelessWidget {
  final StatementImportController controller;
  const _AccountStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [now.year, now.year - 1, now.year - 2];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué cuenta consolidas?', style: context.heading3()),
          const SizedBox(height: 4),
          Text(
            'Elige la cuenta y el mes del estado de cuenta que vas a importar.',
            style: context.textCaption(),
          ),
          const SizedBox(height: 24),
          AppDropdownField<BankAccount>(
            label: 'Cuenta',
            value: controller.selectedAccount,
            hintText: 'Selecciona una cuenta',
            items: controller.accounts
                .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(
                        '${a.name} · ${a.bankEntity.name} · ${a.currency.code}',
                        style: context.textBody1(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: controller.selectAccount,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<int>(
                  label: 'Mes',
                  value: controller.month,
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_monthNames[i], style: context.textBody1()),
                    ),
                  ),
                  onChanged: (v) => controller.setPeriod(month: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppDropdownField<int>(
                  label: 'Año',
                  value: years.contains(controller.year) ? controller.year : years.first,
                  items: years
                      .map((y) => DropdownMenuItem(
                          value: y, child: Text('$y', style: context.textBody1())))
                      .toList(),
                  onChanged: (v) => controller.setPeriod(year: v),
                ),
              ),
            ],
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward,
            onPressed:
                controller.canProceedFromAccount ? controller.goToPickFile : null,
          ),
        ],
      ),
    );
  }
}

// ── Step 2: pick PDF ──────────────────────────────────────────────────────

class _FileStep extends StatelessWidget {
  final StatementImportController controller;
  final VoidCallback onPick;
  const _FileStep({required this.controller, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final acc = controller.selectedAccount!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryChip(
            text:
                '${acc.name} · ${_monthNames[controller.month - 1]} ${controller.year}',
          ),
          const SizedBox(height: 24),
          Text('Selecciona el PDF', style: context.heading3()),
          const SizedBox(height: 4),
          Text(
            'El archivo se procesa en tu dispositivo. Si está protegido, te pediremos la contraseña.',
            style: context.textCaption(),
          ),
          const SizedBox(height: 24),
          if (controller.parsing)
            const SkeletonListLoader(itemCount: 3, itemHeight: 56)
          else ...[
            PrimaryButton(
              label: 'Elegir archivo PDF',
              icon: Icons.upload_file,
              onPressed: onPick,
            ),
            if (controller.parseError != null) ...[
              const SizedBox(height: 16),
              Text(controller.parseError!,
                  style: context.textBody1(color: context.colorError)),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Step 3: review + reconcile ────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final StatementImportController controller;
  final VoidCallback onSubmit;
  const _ReviewStep({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final result = controller.result!;
    final symbol = controller.selectedAccount!.currency.symbol;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ValidationBanner(result: result, symbol: symbol),
              if (controller.monthClosed &&
                  controller.statementFinalBalance != null) ...[
                const SizedBox(height: 12),
                _BalanceCheckBanner(controller: controller, symbol: symbol),
              ],
              const SizedBox(height: 16),
              if (controller.newLines.isNotEmpty) ...[
                Text('Nuevos (${controller.newLines.length})',
                    style: context.heading4()),
                const SizedBox(height: 8),
                ...controller.newLines.map((r) => _NewLineTile(
                      line: r,
                      symbol: symbol,
                      categories: controller.categoriesFor(r.type),
                      onToggle: () => controller.toggleInclude(r),
                      onCategory: (id) => controller.setCategory(r, id),
                      onType: (t) => controller.setType(r, t),
                    )),
              ],
              if (controller.matchedLines.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Ya registrados (${controller.matchedLines.length})',
                    style: context.heading4()),
                const SizedBox(height: 8),
                ...controller.matchedLines
                    .map((r) => _MatchedLineTile(line: r, symbol: symbol)),
              ],
              if (controller.reconciled.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No se detectaron movimientos en el PDF.',
                      style: context.textBody1(color: context.colorTextSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.pendingCategory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: context.colorError),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Asigna una categoría a ${controller.pendingCategory.length} movimiento(s) para poder importar.',
                          style: context.textCaption(color: context.colorError),
                        ),
                      ),
                    ],
                  ),
                ),
              PrimaryButton(
                label: 'Importar ${controller.selectedCount} movimientos',
                icon: Icons.check,
                isLoading: controller.saving,
                onPressed: controller.readyToImport ? onSubmit : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  final StatementParseResult result;
  final String symbol;
  const _ValidationBanner({required this.result, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final hasFooter = result.footerIncome != null || result.footerExpense != null;
    final incomeOk = result.footerIncome == null ||
        (result.footerIncome! - result.parsedIncome).abs() < 0.05;
    final expenseOk = result.footerExpense == null ||
        (result.footerExpense! - result.parsedExpense).abs() < 0.05;
    final ok = incomeOk && expenseOk;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusMdRadius,
        border: Border.all(
          color: hasFooter
              ? (ok ? context.colorSuccess : context.colorError)
              : context.colorBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFooter
                ? (ok ? Icons.verified : Icons.warning_amber_rounded)
                : Icons.info_outline,
            color: hasFooter
                ? (ok ? context.colorSuccess : context.colorError)
                : context.colorMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFooter
                      ? (ok ? 'Totales cuadran con el estado' : 'Revisa: los totales no cuadran')
                      : 'Movimientos detectados',
                  style: context.textSubtitle2(),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ingresos $symbol${result.parsedIncome.toStringAsFixed(2)} · '
                  'Gastos $symbol${result.parsedExpense.toStringAsFixed(2)}'
                  '${hasFooter ? ' (estado: $symbol${(result.footerIncome ?? 0).toStringAsFixed(2)} / $symbol${(result.footerExpense ?? 0).toStringAsFixed(2)})' : ''}',
                  style: context.textCaption(color: context.colorTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reconciles the statement's closing balance against the app's monthly-balance
/// snapshot for a closed month. Updates live as the user toggles which lines to
/// import.
class _BalanceCheckBanner extends StatelessWidget {
  final StatementImportController controller;
  final String symbol;
  const _BalanceCheckBanner({required this.controller, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final ok = controller.balanceReconciles == true;
    final statement = controller.statementFinalBalance ?? 0;
    final projected = controller.projectedFinalBalance ?? 0;
    final diff = (projected - statement).abs();
    final color = ok ? context.colorSuccess : context.colorError;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusMdRadius,
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.account_balance : Icons.error_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok
                      ? 'El saldo cuadra con el mes cerrado'
                      : 'El saldo de cierre no cuadra',
                  style: context.textSubtitle2(),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estado $symbol${statement.toStringAsFixed(2)} · '
                  'Tras importar $symbol${projected.toStringAsFixed(2)}'
                  '${ok ? '' : ' (dif. $symbol${diff.toStringAsFixed(2)})'}',
                  style: context.textCaption(color: context.colorTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewLineTile extends StatelessWidget {
  final ReconciledLine line;
  final String symbol;
  final List<Category> categories;
  final VoidCallback onToggle;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String> onType;

  const _NewLineTile({
    required this.line,
    required this.symbol,
    required this.categories,
    required this.onToggle,
    required this.onCategory,
    required this.onType,
  });

  @override
  Widget build(BuildContext context) {
    final isTransfer = line.type == 'TRANSFER';
    final amountColor = isTransfer
        ? context.colorPrimary
        : (line.type == 'INCOME' ? context.colorSuccess : context.colorError);
    final missingCategory =
        line.include && !isTransfer && line.categoryId == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusMdRadius,
        border: Border.all(
          color: missingCategory ? context.colorError : context.colorBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: line.include,
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.line.description,
                        style: context.textBody1(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(_fmtDate(line.line.date),
                        style: context.textCaption(color: context.colorMuted)),
                  ],
                ),
              ),
              Text(
                '${line.isInflow ? '+' : '-'}$symbol${line.line.amount.toStringAsFixed(2)}',
                style: context.textSubtitle2(color: amountColor),
              ),
            ],
          ),
          if (line.include) ...[
            const SizedBox(height: 8),
            _TypeToggle(type: line.type, onType: onType),
            if (line.type != 'TRANSFER') ...[
              const SizedBox(height: 8),
              AppDropdownField<String>(
                value: line.categoryId,
                hintText: categories.isEmpty
                    ? 'No hay categorías de este tipo'
                    : 'Categoría *',
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: context.textBody1()),
                        ))
                    .toList(),
                onChanged: categories.isEmpty ? (_) {} : onCategory,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Ingreso / Gasto / Transferencia segmented toggle. Lets the user correct a
/// misclassified line — in particular flag movements that are transfers
/// between their own accounts, so they don't count as income/expense.
class _TypeToggle extends StatelessWidget {
  final String type; // INCOME | EXPENSE | TRANSFER
  final ValueChanged<String> onType;
  const _TypeToggle({required this.type, required this.onType});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, String value, Color activeColor) {
      final active = type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onType(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: active ? activeColor.withAlpha(30) : Colors.transparent,
              borderRadius: context.radiusMdRadius,
              border: Border.all(
                  color: active ? activeColor : context.colorBorder),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textCaption(
                    color: active ? activeColor : context.colorTextSecondary),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('Ingreso', 'INCOME', context.colorSuccess),
        const SizedBox(width: 6),
        seg('Gasto', 'EXPENSE', context.colorError),
        const SizedBox(width: 6),
        seg('Transfer.', 'TRANSFER', context.colorPrimary),
      ],
    );
  }
}

class _MatchedLineTile extends StatelessWidget {
  final ReconciledLine line;
  final String symbol;
  const _MatchedLineTile({required this.line, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorSurface.withAlpha(120),
        borderRadius: context.radiusMdRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: context.colorSuccess),
          const SizedBox(width: 10),
          Expanded(
            child: Text(line.line.description,
                style: context.textBody1(color: context.colorTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text('$symbol${line.line.amount.toStringAsFixed(2)}',
              style: context.textCaption(color: context.colorMuted)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String text;
  const _SummaryChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusMdRadius,
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: context.colorPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.textSubtitle2())),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
