import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    await context.read<AuthViewModel>().signIn(_email.text, _password.text);
  }

  Future<void> _demo(String email) async {
    _email.text = email;
    _password.text = 'demo1234';
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return AuthScaffold(
      title: 'Welcome to KIIT Transit',
      subtitle: 'Sign in with your KIIT account to see live buses and EV carts.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('KIIT email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'e.g. 2105123@${AppConstants.allowedEmailDomain}',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: Validators.kiitEmail,
            ),
            const SizedBox(height: 18),
            const FieldLabel('Password'),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
              validator: Validators.password,
            ),
            if (auth.error != null) ...[const SizedBox(height: 14), _ErrorText(auth.error!)],
            const SizedBox(height: 26),
            FilledButton(
              onPressed: auth.busy ? null : _submit,
              child: auth.busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New to KIIT Transit?', style: TextStyle(color: AppColors.muted(context))),
                TextButton(
                  onPressed: () {
                    auth.clearError();
                    context.push(RoutePaths.signup);
                  },
                  child: const Text('Create account'),
                ),
              ],
            ),
            if (AppConstants.isDemoMode) ...[
              const SizedBox(height: 6),
              const OrDivider(),
              const SizedBox(height: 16),
              const DemoBanner(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: auth.busy ? null : () => _demo('student@kiit.ac.in'),
                      icon: const Icon(Icons.school_rounded),
                      label: const Text('Student'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: auth.busy ? null : () => _demo('driver@kiit.ac.in'),
                      icon: const Icon(Icons.airline_seat_recline_normal_rounded),
                      label: const Text('Driver'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.cancelled.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.cancelled, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.cancelled, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Small label shown above a form field, as in the design.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'OR',
          style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
