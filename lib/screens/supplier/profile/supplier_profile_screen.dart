// lib/screens/supplier/profile/supplier_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../providers/auth_provider.dart';


import '../../../providers/supplier_offers_provider.dart';
import '../../../models/supplier_offer.dart';
import '../../../core/api_paths.dart';
import '../../../core/api_service.dart';
import '../../../theme/app_colors.dart';

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
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _address.dispose();
    _allergies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final me = auth.user;

    final offersAsync = ref.watch(supplierOffersProvider(const SupplierOfferFilters()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil fournisseur'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(me: me, offersAsync: offersAsync),

          const SizedBox(height: 16),

          if (me == null)
            _LoginPrompt()
          else
            _ProfileForm(
              form: _form,
              first: _first,
              last: _last,
              phone: _phone,
              address: _address,
              allergies: _allergies,
              saving: _saving,
              onSave: () => _save(context),
            ),

          if (me != null) ...[
            const SizedBox(height: 20),
            _LogoutButton(onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Déconnecté')),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (data is Map && data['detail'] is String) return data['detail'];
      if (res?.statusCode == 403) return "Accès refusé.";
      if (res?.statusCode == 400) return "Données invalides.";
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return "Connexion trop lente. Réessayez.";
      }
    }
    return "Erreur inconnue. Réessayez.";
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic me;
  final AsyncValue<List<SupplierOffer>> offersAsync;
  const _ProfileHeader({required this.me, required this.offersAsync});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me?.email ?? 'Non connecté',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text('Rôle : ${me?.role ?? '—'}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.map_outlined, color: Colors.grey),
              SizedBox(width: 8),
              Text('Région d’opération : Île-de-France'),
            ],
          ),
          const SizedBox(height: 12),
          offersAsync.when(
            loading: () => const _SmallSkeleton(),
            error: (e, _) => Text('Erreur de chargement : $e'),
            data: (offers) {
              final meId = me?.pk;
              final now = DateTime.now();
              final weekAgo = now.subtract(const Duration(days: 7));

              final mine = (meId == null)
                  ? <SupplierOffer>[]
                  : offers.where((o) => o.supplierId == meId).toList();

              final publishedThisWeek = mine.where((o) {
                if (o.status != 'PUBLISHED') return false;
                final from = o.availableFrom;
                return from != null && !from.isBefore(weekAgo);
              }).length;

              return Row(
                children: [

                ],
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> form;
  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController phone;
  final TextEditingController address;
  final TextEditingController allergies;
  final bool saving;
  final VoidCallback onSave;

  const _ProfileForm({
    required this.form,
    required this.first,
    required this.last,
    required this.phone,
    required this.address,
    required this.allergies,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Informations personnelles',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: first,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: last,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save),
                label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryGreenDark,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onLogout,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Se déconnecter'),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'Vous n’êtes pas connecté',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connectez-vous pour modifier votre profil et gérer vos offres.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreenDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSkeleton extends StatelessWidget {
  const _SmallSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
