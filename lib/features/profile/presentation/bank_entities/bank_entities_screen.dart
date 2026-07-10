// lib\features\bank_entities\presentation\bank_entities_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_entities/form_entities_screen.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:flutter/material.dart';

class BankEntitiesScreen extends StatefulWidget {
  const BankEntitiesScreen({super.key});

  @override
  State<BankEntitiesScreen> createState() => _BankEntitiesScreenState();
}

class _BankEntitiesScreenState extends State<BankEntitiesScreen> {
  final BankEntityService _service = BankEntityService();

  List<BankEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    setState(() => _isLoading = true);

    try {
      final entities = await _service.getEntities();

      setState(() {
        _entities = entities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando entidades")));
    }
  }

  /// ➕ Crear entidad
  Future<void> _goToCreateEntity() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormEntityScreen()));

    if (result == true) {
      _loadEntities();
    }
  }

  /// ✏️ Editar entidad
  Future<void> _goToEditEntity(BankEntity entity) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => FormEntityScreen(entity: entity)));

    if (result == true) {
      _loadEntities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: "Entidades bancarias"),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colorPrimary,
        onPressed: _goToCreateEntity,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const SkeletonListLoader()
              : _entities.isEmpty
              /// 🔹 Estado vacío
              ? InsightEmptyState(
                  icon: Icons.account_balance_outlined,
                  title: "No tienes entidades bancarias",
                  description: "Agrega una entidad para empezar a entender tu dinero",
                  actionText: "Crear entidad",
                  onAction: _goToCreateEntity,
                )
              /// 🔹 Lista
              : RefreshIndicator(
                  onRefresh: () async {
                    DataCache.instance.invalidate('bank_entities');
                    await _loadEntities();
                  },
                  child: ListView.separated(
                    itemCount: _entities.length,
                    separatorBuilder: (_, _) => Divider(color: context.colorBorder),
                    // Dentro de ListView.separated
                    itemBuilder: (context, index) {
                      final entity = _entities[index];

                      Color avatarColor;
                      try {
                        avatarColor = entity.colorHex != null
                            ? Color(int.parse("0xFF${entity.colorHex}"))
                            : context.colorSecondary;
                      } catch (_) {
                        avatarColor = context.colorSecondary;
                      }

                      return StaggeredFadeIn(
                        index: index,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),

                          /// 🏦 Avatar con color de entidad
                          leading: CircleAvatar(
                            backgroundColor: avatarColor,
                            child: const Icon(Icons.account_balance, color: Colors.white),
                          ),

                          /// Nombre + código en columna
                          title: Text(entity.name, style: context.textSubtitle2()),
                          subtitle: Text(entity.code, style: context.textCaption()),

                          /// Acción al tocar: editar
                          onTap: () => _goToEditEntity(entity),

                          /// Acciones rápidas: eliminar
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: context.colorError),
                            onPressed: () async {
                              final confirm = await showAppConfirmDialog(
                                context,
                                title: "Eliminar entidad",
                                message: "¿Deseas eliminar '${entity.name}'?",
                                confirmText: "Eliminar",
                                cancelText: "Cancelar",
                                isDestructive: true,
                              );

                              if (confirm) {
                                await _service.deleteEntity(entity.id);
                                _loadEntities();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
