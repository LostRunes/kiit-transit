import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/common.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _edit(BuildContext context, UserModel user) async {
    final name = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone ?? '');
    final form = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 16),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: Validators.name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: Validators.optionalPhone,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      await context.read<AuthViewModel>().updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('If you are on duty, broadcasting will stop and your vehicle will be released.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final auth = context.read<AuthViewModel>();
    if (auth.user?.isDriver ?? false) await context.read<VehicleViewModel>().endShift();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    if (user == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Pod(
            raised: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                UserAvatar(name: user.name, radius: 38),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(color: AppColors.muted(context))),
                const SizedBox(height: 10),
                StatusPill(
                  label: user.role.label,
                  color: user.isDriver ? AppColors.tertiary : AppColors.primary,
                  icon: user.isDriver ? Icons.airline_seat_recline_normal_rounded : Icons.school_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Pod(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const SoftIcon(
                    icon: Icons.person_outline_rounded,
                    color: AppColors.primary,
                    background: AppColors.sageSoft,
                    size: 40,
                  ),
                  title: const Text('Edit profile'),
                  subtitle: Text(user.phone ?? 'Add a phone number'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _edit(context, user),
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const SoftIcon(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.onTeal,
                    background: AppColors.teal,
                    size: 40,
                  ),
                  title: const Text('About ${AppConstants.appName}'),
                  subtitle: const Text('Version 1.0 · live campus transport'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: '1.0.0',
                    applicationIcon: const AppLogo(size: 44),
                    children: const [
                      Text(
                        'Real-time visibility for KIIT campus buses and EV carts. '
                        'Map data © OpenStreetMap contributors, tiles © MapTiler.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (AppConstants.isDemoMode) ...[const SizedBox(height: 14), const DemoBanner()],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cancelled,
              side: BorderSide(color: AppColors.cancelled.withValues(alpha: 0.4), width: 2),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
