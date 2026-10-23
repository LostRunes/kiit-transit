import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';

/// Shared layout for login/sign-up: centred brand mark over a white form pod
/// on a soft sage-to-peach wash.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child, this.showBack = false});

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [AppColors.darkSurface, AppColors.darkSurface]
                : [AppColors.sageSoft.withValues(alpha: 0.6), AppColors.surface, AppColors.peachSoft.withValues(alpha: 0.5)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 64)),
                        const SizedBox(height: 14),
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(color: isDark ? AppColors.primaryLight : AppColors.primary),
                        ),
                        const SizedBox(height: 28),
                        Pod(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                          radius: 32,
                          raised: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted(context), fontSize: 15, height: 1.4),
                              ),
                              const SizedBox(height: 28),
                              child,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showBack)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
