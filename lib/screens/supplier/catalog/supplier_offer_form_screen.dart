// lib/screens/supplier/catalog/supplier_offer_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../providers/supplier_offers_provider.dart';
import '../../../providers/allergens_provider.dart';
import '../../../models/supplier_offer.dart';
import '../../../models/allergen.dart';
import '../../../core/api_paths.dart';
import '../../../core/api_service.dart';
import '../../../theme/app_colors.dart';

class SupplierOfferFormScreen extends ConsumerStatefulWidget {
  static const route = '/supplier/offer/form';
  const SupplierOfferFormScreen({super.key});

  @override
  ConsumerState<SupplierOfferFormScreen> createState() => _SupplierOfferFormScreenState();
}

class _SupplierOfferFormScreenState extends ConsumerState<SupplierOfferFormScreen> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  int? _offerId; // edit mode si fourni

  // champs
  final _name = TextEditingController();
  final _desc = TextEditingController();

  // ❗ Désactivé par défaut maintenant
  bool _isBio = false;

  final _producer = TextEditingController();
  final _region = TextEditingController(text: 'Île-de-France'); // IDF requis
  final _unit = TextEditingController(text: 'kg');
  final _price = TextEditingController();
  final _minQty = TextEditingController(text: '1');
  final _stock = TextEditingController(text: '0');
  DateTime? _from;
  DateTime? _to;

  // Nouvelle sélection d’allergènes
  final List<int> _selectedAllergenIds = [];

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _producer.dispose();
    _region.dispose();
    _unit.dispose();
    _price.dispose();
    _minQty.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['id'] != null && _offerId == null) {
      _offerId = (args['id'] as num).toInt();
      _loadForEdit(_offerId!);
    }
  }

  Future<void> _loadForEdit(int id) async {
    final res = await ApiService.instance.dio.get(ApiPaths.supplierOffer(id));
    final o = SupplierOffer.fromJson(res.data as Map<String, dynamic>);
    setState(() {
      _name.text = o.productName;
      _desc.text = o.description ?? '';
      _isBio = o.isBio;
      _producer.text = o.producerName ?? '';
      _region.text = o.region;
      _unit.text = o.unit;
      _price.text = o.price;
      _minQty.text = o.minOrderQty;
      _stock.text = o.stockQty;
      _from = o.availableFrom;
      _to = o.availableTo;
      _selectedAllergenIds
        ..clear()
        ..addAll(o.allergens); // le modèle de l’offre expose List<int> allergens
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(supplierOfferEditorProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_offerId == null ? 'Nouvelle offre' : 'Modifier l’offre')),
      body: AbsorbPointer(
        absorbing: editorState.isLoading || _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Informations', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Produit (ex: Carottes nouvelles)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _desc,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 8),

                      // --- BIO : désactivé par défaut + modal de certification à l’activation ---
                      SwitchListTile(
                        value: _isBio,
                        onChanged: (v) async {
                          if (v == true) {
                            final ok = await _confirmBio(context);
                            if (!ok) return;
                          }
                          setState(() => _isBio = v);
                        },
                        title: const Text('Bio'),
                        contentPadding: EdgeInsets.zero,
                      ),

                      TextFormField(
                        controller: _producer,
                        decoration: const InputDecoration(labelText: 'Nom producteur (optionnel)'),
                      ),

                      const SizedBox(height: 12),
                      const Text('Tarifs & dispo', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Prix'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: TextFormField(
                            controller: _unit,
                            decoration: const InputDecoration(labelText: 'Unité'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minQty,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Qté minimale'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _stock,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Stock dispo'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: _DateField(
                            label: 'Dispo du',
                            value: _from,
                            onPick: (d) => setState(() => _from = d),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateField(
                            label: 'au',
                            value: _to,
                            onPick: (d) => setState(() => _to = d),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _region,
                        decoration: const InputDecoration(labelText: 'Région (ex: Île-de-France)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),

                      const SizedBox(height: 16),
                      const Text('Allergènes', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _AllergenPicker(
                        selectedIds: _selectedAllergenIds,
                        onChanged: (ids) {
                          setState(() {
                            _selectedAllergenIds
                              ..clear()
                              ..addAll(ids);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _submit(context, submit: false),
                    child: const Text('Enregistrer brouillon'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _submit(context, submit: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryGreenDark,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_offerId == null ? 'Créer & publier' : 'Mettre à jour & publier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmBio(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // <- pas de const ici
        title: Text('Certification Bio'),
        content: Text(
          "En activant l’option Bio, vous certifiez que ce produit dispose d’un "
              "label bio officiel valide dans votre pays (ex. AB, EU Bio, etc.).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Je certifie'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _submit(BuildContext context, {required bool submit}) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final payload = {
      'product_name': _name.text.trim(),
      'description': _desc.text.trim(),
      'is_bio': _isBio, // désormais false par défaut, confirmé si activé
      'producer_name': _producer.text.trim().isEmpty ? null : _producer.text.trim(),
      'region': _region.text.trim(), // IDF attendu par le back
      'unit': _unit.text.trim(),
      'price': _price.text.trim(),
      'min_order_qty': _minQty.text.trim(),
      'stock_qty': _stock.text.trim(),
      'available_from': _from?.toIso8601String().split('T').first,
      'available_to': _to?.toIso8601String().split('T').first,
      if (_selectedAllergenIds.isNotEmpty) 'allergens': _selectedAllergenIds,
    };

    final ed = ref.read(supplierOfferEditorProvider.notifier);
    try {
      if (_offerId == null) {
        final id = await ed.create(payload);
        if (id == null) throw Exception('Création échouée');
        if (submit) await ed.publish(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offre enregistrée')),
        );
        Navigator.pop(context);
      } else {
        final ok = await ed.update(_offerId!, payload);
        if (!ok) throw Exception('Mise à jour échouée');
        if (submit) await ed.publish(_offerId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offre mise à jour')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      final msg = _friendlyError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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
    }
    return "Erreur inconnue. Réessayez.";
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;
  const _DateField({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final txt = value == null
        ? '—'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
        );
        onPick(d);
      },
      child: InputDecorator(
        decoration:  InputDecoration(labelText: label, border: OutlineInputBorder()),
        child: Text(txt),
      ),
    );
  }
}

/// Picker multi-sélection des allergènes + création
class _AllergenPicker extends ConsumerStatefulWidget {
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  const _AllergenPicker({required this.selectedIds, required this.onChanged});

  @override
  ConsumerState<_AllergenPicker> createState() => _AllergenPickerState();
}

class _AllergenPickerState extends ConsumerState<_AllergenPicker> {
  int? _pendingAddId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allergensProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        async.when(
          loading: () => const Text('Chargement…'),
          error: (e, _) => Text('Erreur: $e'),
          data: (list) {
            // Dropdown d’ajout
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _pendingAddId,
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un allergène',
                      border: OutlineInputBorder(),
                    ),
                    items: list
                        .map((a) => DropdownMenuItem<int>(
                      value: a.id,
                      child: Text(a.label),
                    ))
                        .toList(),
                    onChanged: (id) {
                      setState(() => _pendingAddId = id);
                      if (id != null && !widget.selectedIds.contains(id)) {
                        final updated = [...widget.selectedIds, id];
                        widget.onChanged(updated);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        // Chips des sélectionnés
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final id in widget.selectedIds)
              _AllergenChip(id: id, onRemove: () {
                final updated = [...widget.selectedIds]..remove(id);
                widget.onChanged(updated);
              }),
          ],
        ),
      ],
    );
  }

  Future<void> _createAllergenDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel allergène'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Libellé (ex: Arachides)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    );
    if (ok != true) return;

    final label = ctrl.text.trim();
    if (label.isEmpty) return;

    final editor = ref.read(allergenEditorProvider.notifier);
    final created = await editor.create(label: label);
    if (!mounted) return;

    if (created != null) {
      // Ajoute à la sélection
      if (!widget.selectedIds.contains(created.id)) {
        widget.onChanged([...widget.selectedIds, created.id]);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allergène "${created.label}" créé.')),
      );
    } else {
      final err = ref.read(allergenEditorProvider).maybeWhen(
        error: (e, _) => e.toString(),
        orElse: () => "Erreur lors de la création.",
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

/// Affiche un chip avec le label de l’allergène depuis le cache provider
class _AllergenChip extends ConsumerWidget {
  final int id;
  final VoidCallback onRemove;
  const _AllergenChip({required this.id, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allergensProvider);
    return async.when(
      loading: () => const Chip(label: Text('…')),
      error: (_, __) => Chip(label: Text('ID $id')),
      data: (list) {
        final found = list.firstWhere((a) => a.id == id, orElse: () => Allergen(id: id, code: '', label: 'ID $id'));
        return InputChip(
          label: Text(found.label),
          onDeleted: onRemove,
        );
      },
    );
  }
}
