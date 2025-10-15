import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_app/screens/auth/register_screen.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_cta.dart';

// Routes possibles après succès
import '../home/role_home_router.dart';
import '../client/restaurants_list_screen.dart';

// Parsing erreurs DRF/Dio
import '../../core/api_error.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;

  // Bannière erreurs
  List<String> _apiErrors = [];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _apiErrors = []);
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text;

    try {
      final err = await ref.read(authProvider.notifier).login(email: email, password: pwd);

      if (err != null) {
        setState(() => _apiErrors = [err]);
        return;
      }

      if (!mounted) return;

      // Redirection (retour)
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['returnTo'] is String) {
        final String returnTo = args['returnTo'] as String;
        final Object? returnArgs = args['returnArgs'];
        Navigator.pushNamedAndRemoveUntil(context, returnTo, (_) => false, arguments: returnArgs);
        return;
      }

      // Sinon : page par défaut (ou RoleHomeRouter si tu préfères)
      Navigator.pushNamedAndRemoveUntil(context, ClientRestaurantsScreen.route, (_) => false);
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
          const AuthHeader(title: 'Se connecter', subtitle: 'Bonjour,'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
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
                            AuthField(
                              controller: _emailCtrl,
                              hint: 'Adresse email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Adresse email requise';
                                final re = RegExp(r'^\S+@\S+\.\S+$');
                                if (!re.hasMatch(v.trim())) return 'Adresse email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AuthField(
                              controller: _pwdCtrl,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Mot de passe requis';
                                if (v.length < 6) return '6 caractères minimum';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    PrimaryCta(
                      text: 'Se connecter',
                      loading: auth.loading,
                      onPressed: auth.loading ? null : _submit,
                    ),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, RegisterScreen.route);
                      },
                      child: const Text("Créer un compte"),
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
