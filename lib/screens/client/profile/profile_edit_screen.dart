import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/api_service.dart';
import '../../../core/api_paths.dart';
import '../../../models/user.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  static const route = '/c/profile/edit';
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _allergies;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final VegUser? u = ref.read(authProvider).user;
    _firstName = TextEditingController(text: u?.firstName ?? '');
    _lastName  = TextEditingController(text: u?.lastName ?? '');
    _phone     = TextEditingController(text: u?.profile?.phone ?? '');
    _address   = TextEditingController(text: u?.profile?.address ?? '');
    _allergies = TextEditingController(text: u?.profile?.allergies ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = {
      'first_name': _firstName.text.trim(),
      'last_name' : _lastName.text.trim(),
      'profile': {
        // on envoie null si vide (tes champs acceptent blank/null)
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'allergies': _allergies.text.trim().isEmpty ? null : _allergies.text.trim(),
      }
    };

    setState(() => _saving = true);
    try {
      await ApiService.instance.dio.patch(ApiPaths.meUpdate, data: payload);
      // recharger /me pour mettre à jour l’état global
      await ref.read(authProvider.notifier).fetchMe();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de la mise à jour")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _saving;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes informations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    textInputAction: TextInputAction.next,
                    enabled: !disabled,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    textInputAction: TextInputAction.next,
                    enabled: !disabled,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    enabled: !disabled,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                    keyboardType: TextInputType.streetAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !disabled,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _allergies,
                    decoration: const InputDecoration(labelText: 'Allergies'),
                    maxLines: 2,
                    enabled: !disabled,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: disabled ? null : _save,
                      icon: disabled ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) : const Icon(Icons.save),
                      label: Text(disabled ? 'Enregistrement...' : 'Enregistrer'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
