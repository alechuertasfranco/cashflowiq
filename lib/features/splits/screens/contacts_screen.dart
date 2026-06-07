// lib/features/splits/screens/contacts_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/splits/data/contact_service.dart';
import 'package:cashflowiq/features/splits/screens/form_contact_screen.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _service = ContactService();

  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Contactos', style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
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
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _contacts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return SwipeToDelete(
                          key: ValueKey(contact.id),
                          onDelete: () => _delete(contact),
                          child: _ContactTile(
                            contact: contact,
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
  final VoidCallback onTap;

  const _ContactTile({required this.contact, required this.onTap});

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
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
