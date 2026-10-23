import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'auth_scaffold.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
    if (!mounted || !ok || !auth.pendingConfirmation) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_rounded, size: 36),
        title: const Text('Confirm your email'),
        content: Text('We sent a confirmation link to ${_email.text.trim()}. Open it, then sign in.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return AuthScaffold(
      showBack: true,
      title: 'Create your account',
      subtitle: 'Only @${AppConstants.allowedEmailDomain} addresses can register.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'KIIT email',
                hintText: 'rollno@${AppConstants.allowedEmailDomain}',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: Validators.kiitEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
              validator: Validators.optionalPhone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_rounded)),
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 14),
              Text(
                auth.error!,
                style: const TextStyle(color: AppColors.cancelled, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: auth.busy ? null : _submit,
              child: auth.busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Text('Create account'),
            ),
            const SizedBox(height: 12),
            Text(
              'New accounts are students. Transport staff get driver access from the admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted(context), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
