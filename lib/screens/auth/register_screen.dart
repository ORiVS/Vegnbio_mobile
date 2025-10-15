// lib/screens/auth/register_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/role_segment.dart'; // ok si ton composant existe, on filtre sa valeur côté code
import '../../widgets/auth_header.dart';
import '../../widgets/primary_cta.dart';

import '../../core/api_service.dart';
import '../../core/api_paths.dart';
import '../../core/api_error.dart';

import '../../models/user.dart';
import '../home/role_home_router.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Champs communs
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();

  // Rôle (seulement CLIENT ou FOURNISSEUR dans l’app mobile)
  String _role = 'CLIENT';

  // Fournisseur (profile)
  final _companyCtrl = TextEditingController();
  final _productTypeCtrl = TextEditingController();
  String? _region; // Dropdown value
  String? _regionMsg; // Alerte si != IDF

  // Erreurs API globales (bandeau)
  List<String> _apiErrors = [];

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _companyCtrl.dispose();
    _productTypeCtrl.dispose();
    super.dispose();
  }

  // ---------- Régions France métropolitaine + DROM ----------
  static const String _IDF = 'Île-de-France';
  static const List<String> _FR_REGIONS = <String>[
    'Auvergne-Rhône-Alpes',
    'Bourgogne-Franche-Comté',
    'Bretagne',
    'Centre-Val de Loire',
    'Corse',
    'Grand Est',
    'Hauts-de-France',
    'Normandie',
    'Nouvelle-Aquitaine',
    'Occitanie',
    'Pays de la Loire',
    'Provence-Alpes-Côte d’Azur',
    'Guadeloupe',
    'Martinique',
    'Guyane',
    'La Réunion',
    'Mayotte',
    'Île-de-France',
  ];

  bool get _isSupplier => _role == 'FOURNISSEUR';
  bool get _isIdf => (_region ?? '').trim().toLowerCase() == _IDF.toLowerCase();

  void _onRoleChanged(String r) {
    // L’app mobile ne gère pas RESTAURATEUR → on ignore et on informe
    if (r == 'RESTAURATEUR') {
      setState(() {
        _apiErrors = ['Le rôle “Restaurateur” n’est pas disponible sur l’application mobile.'];
        _role = 'CLIENT';
      });
      return;
    }
    setState(() {
      _role = r;
      _apiErrors = [];
      _regionMsg = null;
    });
  }

  void _onRegionChanged(String? v) {
    setState(() {
      _region = v;
      if (_isSupplier) {
        if (_region != null && !_isIdf) {
          _regionMsg = "Pour le moment, nous n’acceptons que des producteurs d’Île-de-France.";
        } else {
          _regionMsg = null;
        }
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _apiErrors = []);

    if (!_formKey.currentState!.validate()) return;

    // Blocage front pour Fournisseur hors IDF (même règle que le back)
    if (_isSupplier && !_isIdf) {
      setState(() {
        _apiErrors = ["Région non autorisée. Exigée: Île-de-France."];
      });
      return;
    }

    // Construit le profile selon le rôle
    Map<String, dynamic>? profile;
    if (_isSupplier) {
      profile = {
        "company_name": _companyCtrl.text.trim(),
        "product_type": _productTypeCtrl.text.trim(),
        "region": _region?.trim(),
      };
    } else {
      profile = {}; // client: rien d’obligatoire, mais structure ok
    }

    try {
      final err = await ref.read(authProvider.notifier).register(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        role: _role,
        restaurantId: null, // ❌ plus de restaurateur sur mobile
        profile: profile,
      );

      if (err != null) {
        setState(() => _apiErrors = [err]);
        return;
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, RoleHomeRouter.route, (_) => false);
      }
    } on DioException catch (e) {
      final apiErr = ApiError.fromDio(e);
      setState(() => _apiErrors = apiErr.messages);
    } catch (e) {
      setState(() => _apiErrors = ["Erreur inconnue : $e"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(title: 'Créer un compte', subtitle: 'Bienvenue 👋'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    // Bandeau erreurs API si présent
                    if (_apiErrors.isNotEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Erreurs',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._apiErrors.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AuthField(
                                    controller: _firstCtrl,
                                    hint: 'Prénom',
                                    icon: Icons.person_outline,
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Votre prénom est obligatoire'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AuthField(
                                    controller: _lastCtrl,
                                    hint: 'Nom',
                                    icon: Icons.person_outline,
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Votre nom est obligatoire'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AuthField(
                              controller: _emailCtrl,
                              hint: 'Adresse mail',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Votre adresse mail est obligatoire';
                                }
                                final re = RegExp(r'^\S+@\S+\.\S+$');
                                if (!re.hasMatch(v.trim())) return 'Adresse mail invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AuthField(
                              controller: _pwdCtrl,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline,
                              obscure: true,
                              validator: (v) => v == null || v.length < 6 ? '6 caractères min.' : null,
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Quel est votre rôle'),
                            ),
                            const SizedBox(height: 8),

                            // ⚠️ On garde le widget RoleSegment mais on filtre RESTAURATEUR côté code
                            RoleSegment(selected: _role, onChanged: _onRoleChanged),

                            // ---------- Bloc FOURNISSEUR ----------
                            if (_isSupplier) ...[
                              const SizedBox(height: 16),
                              AuthField(
                                controller: _companyCtrl,
                                hint: 'Raison sociale (producteur)',
                                icon: Icons.factory_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'La raison sociale est obligatoire'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              AuthField(
                                controller: _productTypeCtrl,
                                hint: 'Type de produit (ex. Légumes, Fruits…)',
                                icon: Icons.eco_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Le type de produit est obligatoire'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _region,
                                items: _FR_REGIONS
                                    .map((r) => DropdownMenuItem<String>(
                                  value: r,
                                  child: Text(r),
                                ))
                                    .toList(),
                                onChanged: _onRegionChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Région de provenance',
                                  prefixIcon: Icon(Icons.map_outlined),
                                ),
                                validator: (_) {
                                  if (_region == null || _region!.trim().isEmpty) {
                                    return 'Choisissez votre région';
                                  }
                                  if (!_isIdf) {
                                    return 'Nous acceptons uniquement les producteurs d’Île-de-France.';
                                  }
                                  return null;
                                },
                              ),
                              if (_regionMsg != null) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _regionMsg!,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    PrimaryCta(
                      text: "Créer votre compte",
                      loading: auth.loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Vous avez déjà un compte ? "),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
                          child: const Text('Se connecter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
