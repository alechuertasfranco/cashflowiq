// lib/core/widgets/update_dialog.dart

import 'package:flutter/material.dart';

import 'package:cashflowiq/core/services/update_service.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/shared/models/update_info.dart';

/// Shows the update prompt and drives the download → install flow.
/// If [info.forceUpdate] is true the dialog can't be dismissed without updating.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (context) => PopScope(canPop: !info.forceUpdate, child: _UpdateDialog(info: info)),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final path = await UpdateService.downloadApk(
        widget.info.apkUrl,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );
      await UpdateService.installApk(path);
    } catch (e) {
      if (mounted) setState(() => _error = "No se pudo descargar la actualización. Intenta de nuevo.");
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null;

    return AlertDialog(
      title: Text('Nueva versión disponible', style: context.heading5()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versión ${widget.info.latestVersion}', style: context.textSubtitle2(color: context.colorTextSecondary)),
          if (widget.info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(widget.info.releaseNotes, style: context.textBody2()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: context.textBody2(color: context.colorError)),
          ],
          if (downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress! > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text('${((_progress ?? 0) * 100).toStringAsFixed(0)}%', style: context.textCaption()),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            if (!widget.info.forceUpdate && !downloading) ...[
              Expanded(
                child: GhostButton(label: 'Más tarde', onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: downloading ? 'Descargando…' : 'Actualizar ahora',
                onPressed: downloading ? null : _startUpdate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
