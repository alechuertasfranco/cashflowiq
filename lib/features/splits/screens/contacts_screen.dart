// lib/features/splits/screens/contacts_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/splits/data/contact_service.dart';
import 'package:cashflowiq/features/splits/data/split_service.dart';
import 'package:cashflowiq/features/splits/screens/form_contact_screen.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _service = ContactService();
  final _splitService = SplitService();

  List<Contact> _contacts = [];
  // contact.id → total unsettled amount they owe the user
  Map<int, double> _balances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.fetchAll(),
        _splitService.fetchSplits(settled: false, limit: 500),
      ]);
      if (!mounted) return;

      final contacts = results[0] as List<Contact>;
      final unsettled = results[1] as List;

      // Sum unsettled amounts per contact
      final balances = <int, double>{};
      for (final split in unsettled) {
        final id = split.contact.id;
        balances[id] = (balances[id] ?? 0) + split.amount;
      }

      setState(() {
        _contacts = contacts;
        _balances = balances;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los contactos')),
      );
    }
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormContactScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _goToEdit(Contact contact) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormContactScreen(existing: contact)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Contact contact) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.delete(contact.id);
      await _load();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Contacto eliminado')),
      );
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al eliminar el contacto')),
      );
    }
  }

  Future<void> _importFromPhone() async {
    final granted = await fc.FlutterContacts.requestPermission(readonly: true);
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de contactos denegado')),
      );
      return;
    }

    final phoneContacts =
        await fc.FlutterContacts.getContacts(withProperties: true);

    if (!mounted) return;

    // Filter out contacts that already exist (match by name or phone)
    final existingNames =
        _contacts.map((c) => c.name.toLowerCase().trim()).toSet();
    final existingPhones = _contacts
        .where((c) => c.phone != null && c.phone!.isNotEmpty)
        .map((c) => c.phone!.trim())
        .toSet();

    final available = phoneContacts.where((pc) {
      final name = pc.displayName.toLowerCase().trim();
      if (existingNames.contains(name)) return false;
      if (pc.phones.isNotEmpty) {
        final phone = pc.phones.first.number.trim();
        if (existingPhones.contains(phone)) return false;
      }
      return true;
    }).cast<fc.Contact>().toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay contactos nuevos para importar')),
      );
      return;
    }

    await _showImportBottomSheet(available);
  }

  Future<void> _showImportBottomSheet(
      List<fc.Contact> available) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final selected = <int>{};
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Importar contactos',
                        style: AppTextStyles.h400(ctx),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: available.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final pc = available[index];
                          final phone = pc.phones.isNotEmpty
                              ? pc.phones.first.number
                              : null;
                          final isSelected = selected.contains(index);
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  const BorderSide(color: AppColors.border),
                            ),
                            tileColor: AppColors.surface,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondary,
                              child: Text(
                                pc.displayName.isNotEmpty
                                    ? pc.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            title: Text(
                              pc.displayName,
                              style: AppTextStyles.subtitle1(ctx),
                            ),
                            subtitle: phone != null
                                ? Text(
                                    phone,
                                    style: AppTextStyles.caption(ctx,
                                        color: AppColors.textSecondary),
                                  )
                                : null,
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setSheetState(() {
                                  if (val == true) {
                                    selected.add(index);
                                  } else {
                                    selected.remove(index);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setSheetState(() {
                                if (isSelected) {
                                  selected.remove(index);
                                } else {
                                  selected.add(index);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: selected.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await _saveImported(available, selected);
                                },
                          child: Text(
                            'Importar seleccionados',
                            style: AppTextStyles.subtitle2(ctx,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveImported(
      List<fc.Contact> available, Set<int> selectedIndices) async {
    final messenger = ScaffoldMessenger.of(context);
    int saved = 0;
    int failed = 0;

    for (final index in selectedIndices) {
      final pc = available[index];
      final phone =
          pc.phones.isNotEmpty ? pc.phones.first.number : null;
      final email =
          pc.emails.isNotEmpty ? pc.emails.first.address : null;

      try {
        await _service.create({
          'name': pc.displayName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        });
        saved++;
      } catch (e) {
        debugPrint('Error importing contact ${pc.displayName}: $e');
        failed++;
      }
    }

    await _load();

    if (!mounted) return;

    final message = failed == 0
        ? '$saved contacto${saved == 1 ? '' : 's'} importado${saved == 1 ? '' : 's'}'
        : '$saved importado${saved == 1 ? '' : 's'}, $failed con error';

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Contactos', style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_phone, color: AppColors.primary),
            onPressed: _importFromPhone,
            tooltip: 'Importar del teléfono',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _goToCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _contacts.isEmpty
                ? InsightEmptyState(
                    icon: Icons.people_outline,
                    title: 'Sin contactos',
                    description:
                        'Agrega contactos para dividir gastos fácilmente con ellos',
                    actionText: 'Agregar contacto',
                    onAction: _goToCreate,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      DataCache.instance.invalidate('contacts');
                      DataCache.instance.invalidate('splits_pending');
                      await _load();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _contacts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return SwipeToDelete(
                          key: ValueKey(contact.id),
                          onDelete: () => _delete(contact),
                          child: _ContactTile(
                            contact: contact,
                            balance: _balances[contact.id],
                            onTap: () => _goToEdit(contact),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final double? balance;
  final VoidCallback onTap;

  const _ContactTile({required this.contact, this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (contact.email != null && contact.email!.isNotEmpty) contact.email!,
      if (contact.phone != null && contact.phone!.isNotEmpty) contact.phone!,
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty
                      ? contact.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.h400(context)
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: AppTextStyles.h600(context)),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption(context,
                          color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _BalanceBadge(balance: balance),
          ],
        ),
      ),
    );
  }
}

class _BalanceBadge extends StatelessWidget {
  final double? balance;

  const _BalanceBadge({this.balance});

  @override
  Widget build(BuildContext context) {
    final hasDebt = balance != null && balance! > 0.005;

    if (!hasDebt) {
      return Text(
        'Al día',
        style: AppTextStyles.caption(context, color: AppColors.muted),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Te debe\n${balance!.toStringAsFixed(2)}',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption(context, color: AppColors.successStrong),
      ),
    );
  }
}
