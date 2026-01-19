import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _username,
                  label: 'Username (optional)',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                if (auth.error != null) ...[
                  Text(auth.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (_password.text != _confirm.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password does not match'),
                                ),
                              );
                              return;
                            }
                            final ok = await context
                                .read<AuthProvider>()
                                .signup(
                                  email: _email.text.trim(),
                                  username: _username.text.trim().isEmpty
                                      ? null
                                      : _username.text.trim(),
                                  password: _password.text,
                                );
                            if (!mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Account created. Please login.',
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                    child: auth.isLoading
                        ? const Text('...')
                        : const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
