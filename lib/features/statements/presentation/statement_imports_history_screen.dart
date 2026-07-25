// lib/features/statements/presentation/statement_imports_history_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/features/statements/data/statement_import_service.dart';
import 'package:cashflowiq/shared/models/statement_import.dart';
import 'package:flutter/material.dart';

const _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class StatementImportsHistoryScreen extends StatefulWidget {
  const StatementImportsHistoryScreen({super.key});

  @override
  State<StatementImportsHistoryScreen> createState() =>
      _StatementImportsHistoryScreenState();
}

class _StatementImportsHistoryScreenState
    extends State<StatementImportsHistoryScreen> {
  final _service = StatementImportService();
  List<StatementImportBatch> _batches = [];
  bool _loading = true;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.list();
      if (!mounted) return;
      setState(() {
        _batches = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _undo(StatementImportBatch batch) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Deshacer importación',
      message:
          'Se eliminarán los ${batch.importedCount} movimientos creados en esta importación. Esta acción no se puede deshacer.',
      confirmText: 'Deshacer',
      isDestructive: true,
    );
    if (!confirm) return;

    setState(() => _deletingId = batch.id);
    try {
      await _service.delete(batch.id);
      if (!mounted) return;
      setState(() {
        _batches.removeWhere((b) => b.id == batch.id);
        _deletingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importación deshecha')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo deshacer la importación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: 'Importaciones'),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonListLoader(itemCount: 5, itemHeight: 76),
              )
            : _batches.isEmpty
                ? Center(
                    child: Text(
                      'Aún no has importado estados de cuenta.',
                      style: context.textBody1(color: context.colorTextSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _batches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _BatchTile(
                        batch: _batches[i],
                        deleting: _deletingId == _batches[i].id,
                        onUndo: () => _undo(_batches[i]),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  final StatementImportBatch batch;
  final bool deleting;
  final VoidCallback onUndo;

  const _BatchTile({
    required this.batch,
    required this.deleting,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final period = '${_monthNames[(batch.month - 1).clamp(0, 11)]} ${batch.year}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusMdRadius,
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: context.colorPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period, style: context.textSubtitle2()),
                const SizedBox(height: 2),
                Text(
                  '${batch.importedCount} movimientos'
                  '${batch.bank != null ? ' · ${batch.bank}' : ''}',
                  style: context.textCaption(color: context.colorTextSecondary),
                ),
              ],
            ),
          ),
          if (deleting)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(Icons.undo, color: context.colorError),
              tooltip: 'Deshacer',
              onPressed: onUndo,
            ),
        ],
      ),
    );
  }
}
