import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/api_paths.dart';
import '../../../core/api_service.dart';

class SupplierProfileScreen extends ConsumerStatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  ConsumerState<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends ConsumerState<SupplierProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _allergies;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).user;
    _first = TextEditingController(text: u?.firstName ?? '');
    _last = TextEditingController(text: u?.lastName ?? '');
    _phone = TextEditingController(text: u?.profile?.phone ?? '');
    _address = TextEditingController(text: u?.profile?.address ?? '');
    _allergies = TextEditingController(text: u?.profile?.allergies ?? '');
  }

  @override
  void dispose() { _first.dispose(); _last.dispose(); _phone.dispose(); _address.dispose(); _allergies.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final u = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil fournisseur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u?.email ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Rôle: ${u?.role ?? '—'}'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(children: [
                  TextFormField(controller: _first, decoration: const InputDecoration(labelText: 'Prénom')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _last, decoration: const InputDecoration(labelText: 'Nom')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Adresse')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _allergies, decoration: const InputDecoration(labelText: 'Allergies')),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : () async {
              setState(()=>_saving = true);
              try {
                await ApiService.instance.dio.patch(ApiPaths.meUpdate, data: {
                  'first_name': _first.text.trim(),
                  'last_name': _last.text.trim(),
                  'profile': {
                    'phone': _phone.text.trim(),
                    'address': _address.text.trim(),
                    'allergies': _allergies.text.trim(),
                  },
                });
                await ref.read(authProvider.notifier).fetchMe();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de mise à jour')));
                }
              } finally {
                if (mounted) setState(()=>_saving = false);
              }
            },
            child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}
