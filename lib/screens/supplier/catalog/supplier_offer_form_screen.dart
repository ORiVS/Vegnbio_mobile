import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../models/supplier_offer.dart';
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
  bool _isBio = true; // par défaut true (requis par le back)
  final _producer = TextEditingController();
  final _region = TextEditingController(text: 'Île-de-France'); // IDF requis
  final _unit = TextEditingController(text: 'kg');
  final _price = TextEditingController();
  final _minQty = TextEditingController(text: '1');
  final _stock = TextEditingController(text: '0');
  DateTime? _from;
  DateTime? _to;
  final _allergensCsv = TextEditingController(); // ids séparés par virgules (optionnel)

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
    _allergensCsv.dispose();
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
      _allergensCsv.text = o.allergens.join(',');
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
                      SwitchListTile(
                        value: _isBio,
                        onChanged: (v) => setState(() => _isBio = v),
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
                            keyboardType: TextInputType.number,
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
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qté minimale'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _stock,
                            keyboardType: TextInputType.number,
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
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _allergensCsv,
                        decoration: const InputDecoration(
                          labelText: 'Allergènes (IDs séparés par , — optionnel)',
                          helperText: 'Laisse vide si non applicable',
                        ),
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

  Future<void> _submit(BuildContext context, {required bool submit}) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final payload = {
      'product_name': _name.text.trim(),
      'description': _desc.text.trim(),
      'is_bio': _isBio, // requis par le back (true attendu)
      'producer_name': _producer.text.trim().isEmpty ? null : _producer.text.trim(),
      'region': _region.text.trim(), // IDF attendu par le back
      'unit': _unit.text.trim(),
      'price': _price.text.trim(),
      'min_order_qty': _minQty.text.trim(),
      'stock_qty': _stock.text.trim(),
      'available_from': _from?.toIso8601String().split('T').first,
      'available_to': _to?.toIso8601String().split('T').first,
      if (_allergensCsv.text.trim().isNotEmpty)
        'allergens': _allergensCsv.text
            .trim()
            .split(',')
            .where((x) => x.trim().isNotEmpty)
            .map((x) => int.parse(x.trim()))
            .toList(),
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de sauvegarde')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(txt),
      ),
    );
  }
}
