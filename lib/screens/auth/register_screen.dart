import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/role_segment.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_cta.dart';
import '../../core/api_service.dart';
import '../../core/api_paths.dart';
import '../../models/user.dart';
import '../home/role_home_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  String _role = 'CLIENT';

  bool _loadingRestaurants = false;
  String? _restaurantsError;
  List<RestaurantLite> _restaurants = [];
  int? _selectedRestaurantId;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _loadingRestaurants = true;
      _restaurantsError = null;
    });
    try {
      final res = await ApiService.instance.dio.get(ApiPaths.restaurantsList);
      final data = res.data;
      if (data is! List) {
        throw Exception('Payload inattendu depuis ${ApiPaths.restaurantsList}');
      }
      final list = data
          .map<RestaurantLite>((e) => RestaurantLite(
        id: (e['id'] as num).toInt(),
        name: (e['name'] ?? '').toString(),
        city: e['city']?.toString(),
      ))
          .toList();
      setState(() => _restaurants = list);
      print('[REGISTER] restaurants loaded: ${list.length}');
    } catch (e) {
      print('[REGISTER] load restaurants failed: $e');
      setState(() => _restaurantsError = "Impossible de charger les restaurants");
    } finally {
      setState(() => _loadingRestaurants = false);
    }
  }

  void _onRoleChanged(String r) {
    setState(() {
      _role = r;
      _selectedRestaurantId = null;
      _restaurantsError = null;
    });
    if (r == 'RESTAURATEUR' && _restaurants.isEmpty && !_loadingRestaurants) {
      _loadRestaurants();
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
                                    validator: (v) => v == null || v.isEmpty ? 'Votre prénom est obligatoire' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AuthField(
                                    controller: _lastCtrl,
                                    hint: 'Nom',
                                    icon: Icons.person_outline,
                                    validator: (v) => v == null || v.isEmpty ? 'Votre nom est obligatoire' : null,
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
                              validator: (v) => v == null || v.isEmpty ? 'Votre adresse mail est obligatoire' : null,
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
                            RoleSegment(selected: _role, onChanged: _onRoleChanged),

                            if (_role == 'RESTAURATEUR') ...[
                              const SizedBox(height: 12),
                              if (_loadingRestaurants)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_restaurantsError != null)
                                Row(
                                  children: [
                                    Expanded(child: Text(_restaurantsError!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                                    TextButton(
                                      onPressed: _loadRestaurants,
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                )
                              else
                                DropdownButtonFormField<int>(
                                  value: _selectedRestaurantId,
                                  items: _restaurants
                                      .map((r) => DropdownMenuItem<int>(
                                    value: r.id,
                                    child: Text('${r.name}${r.city != null ? " (${r.city})" : ""}'),
                                  ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedRestaurantId = v),
                                  decoration: const InputDecoration(
                                    hintText: 'Sélectionner un restaurant',
                                    prefixIcon: Icon(Icons.storefront_outlined),
                                  ),
                                  validator: (_) => _role == 'RESTAURATEUR' && _selectedRestaurantId == null
                                      ? 'Choisissez un restaurant'
                                      : null,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryCta(
                      text: "Créer votre compte",
                      loading: auth.loading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final restaurantId = _role == 'RESTAURATEUR' ? _selectedRestaurantId : null;
                        if (_role == 'RESTAURATEUR' && restaurantId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez choisir un restaurant')),
                          );
                          return;
                        }

                        final err = await ref.read(authProvider.notifier).register(
                          email: _emailCtrl.text.trim(),
                          password: _pwdCtrl.text,
                          firstName: _firstCtrl.text.trim(),
                          lastName: _lastCtrl.text.trim(),
                          role: _role,
                          restaurantId: restaurantId,
                        );

                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        } else if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, RoleHomeRouter.route, (_) => false);
                        }
                      },
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
