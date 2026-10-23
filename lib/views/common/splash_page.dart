import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common.dart';

/// Shown while the stored session is restored; the router then redirects.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthViewModel>();
      // Keep the brand on screen briefly even when restore is instant.
      await Future.wait([auth.restore(), Future<void>.delayed(const Duration(milliseconds: 900))]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = isDark ? AppColors.primaryLight : AppColors.primary;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [AppColors.darkSurface, AppColors.darkSurface]
                : [AppColors.sageSoft, AppColors.surface, AppColors.peachSoft.withValues(alpha: 0.6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              const AppLogo(size: 96),
              const SizedBox(height: 28),
              Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: brand)),
              const SizedBox(height: 8),
              Text(
                AppConstants.tagline,
                style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w500, fontSize: 15),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.sage, backgroundColor: AppColors.sageSoft),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
