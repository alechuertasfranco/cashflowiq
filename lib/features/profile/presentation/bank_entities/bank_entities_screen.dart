// lib\features\bank_entities\presentation\bank_entities_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Entidades bancarias", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _goToCreateEntity,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _entities.isEmpty
              /// 🔹 Estado vacío
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text("No tienes entidades bancarias", style: AppTextStyles.subtitle1(context)),
                      const SizedBox(height: 8),
                      Text(
                        "Agrega bancos para estructurar tu dinero",
                        style: AppTextStyles.caption(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _goToCreateEntity, child: const Text("Crear entidad")),
                    ],
                  ),
                )
              /// 🔹 Lista
              : RefreshIndicator(
                  onRefresh: _loadEntities,
                  child: ListView.separated(
                    itemCount: _entities.length,
                    separatorBuilder: (_, _) => const Divider(color: AppColors.border),
                    // Dentro de ListView.separated
                    itemBuilder: (context, index) {
                      final entity = _entities[index];

                      Color avatarColor;
                      try {
                        avatarColor = entity.colorHex != null
                            ? Color(int.parse("0xFF${entity.colorHex}"))
                            : AppColors.secondary;
                      } catch (_) {
                        avatarColor = AppColors.secondary;
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),

                        /// 🏦 Avatar con color de entidad
                        leading: CircleAvatar(
                          backgroundColor: avatarColor,
                          child: const Icon(Icons.account_balance, color: Colors.white),
                        ),

                        /// Nombre + código en columna
                        title: Text(entity.name, style: AppTextStyles.subtitle2(context)),
                        subtitle: Text(entity.code, style: AppTextStyles.caption(context)),

                        /// Acción al tocar: editar
                        onTap: () => _goToEditEntity(entity),

                        /// Acciones rápidas: eliminar
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Eliminar entidad"),
                                content: Text("¿Deseas eliminar '${entity.name}'?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _service.deleteEntity(entity.id);
                              _loadEntities();
                            }
                          },
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
