import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.emailPrefill});
  final String emailPrefill;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _email;
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.emailPrefill);
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(controller: _email, label: 'Email'),
                const SizedBox(height: 12),
                AppTextField(controller: _otp, label: 'OTP'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _newPassword,
                  label: 'New Password',
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
                            final ok = await context
                                .read<AuthProvider>()
                                .resetPassword(
                                  email: _email.text.trim(),
                                  otp: _otp.text.trim(),
                                  newPassword: _newPassword.text,
                                );
                            if (!mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset success. Login now.',
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                    child: auth.isLoading
                        ? const Text('...')
                        : const Text('Reset'),
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
