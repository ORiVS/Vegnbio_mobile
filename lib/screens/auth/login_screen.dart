import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_cta.dart';
import 'register_screen.dart';
import '../home/role_home_router.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(title: 'Sign in', subtitle: 'Good morning,'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            AuthField(
                              controller: _emailCtrl,
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                            ),
                            const SizedBox(height: 12),
                            AuthField(
                              controller: _pwdCtrl,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryCta(
                      text: 'Sign in',
                      loading: auth.loading,
                      onPressed: auth.loading
                          ? null
                          : () async {
                        print('[UI] Sign in tapped');
                        if (!_formKey.currentState!.validate()) {
                          print('[UI] Form invalid');
                          return;
                        }
                        final email = _emailCtrl.text.trim();
                        final pwd = _pwdCtrl.text;
                        print('[UI] Calling login(email=$email, pwdLen=${pwd.length})');

                        final error = await ref
                            .read(authProvider.notifier)
                            .login(email: email, password: pwd);

                        print(
                            '[UI] login() returned error=$error; isAuth=${ref.read(authProvider).isAuthenticated}');
                        if (error != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                        } else {
                          if (context.mounted) {
                            print('[UI] Navigate -> RoleHomeRouter');
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RoleHomeRouter.route,
                                  (_) => false,
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No account? "),
                        TextButton(
                          onPressed: () {
                            print('[UI] Navigate -> RegisterScreen');
                            Navigator.pushNamed(context, RegisterScreen.route);
                          },
                          child: const Text('Create one'),
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
