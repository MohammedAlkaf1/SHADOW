import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/platform_client.dart';
import '/student/student_profile_provider.dart';
import '/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  static String routeName = 'SplashScreen';
  static String routePath = '/';

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> {
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  /// Keeps the splash's original ~2s minimum display time, but routes based
  /// on whether a platform session is already cached: logged in -> hydrate
  /// the profile (offline-first — getStudentProfile() falls back to cache on
  /// its own, so this never hangs the splash screen waiting on a dead
  /// network) and go straight to mode selection; not logged in -> the new
  /// login screen.
  Future<void> _decideNextRoute() async {
    final delay = Future.delayed(const Duration(seconds: 2));
    final loggedIn = await PlatformClient.isLoggedIn;

    if (loggedIn) {
      final profileResult = await PlatformClient.getStudentProfile();
      if (mounted && profileResult.isSuccess) {
        context.read<StudentProfileProvider>().applyPlatformProfile(
              enabledTools: profileResult.data.enabledTools,
              directives: profileResult.data.directives,
            );
      }
      PlatformClient.startAutoFlushTimer();
    }

    await delay;
    if (!mounted) return;
    context.go(
      loggedIn ? WelcomeSelectionWidget.routePath : LoginWidget.routePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                color: AppColors.onNavy.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(color: AppColors.terracotta, width: 2.0),
              ),
              alignment: Alignment.center,
              child: Text(
                'ش',
                style: GoogleFonts.tajawal(
                  fontSize: 52.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.terracotta,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'شادو',
              style: GoogleFonts.tajawal(
                fontSize: 44.0,
                fontWeight: FontWeight.w900,
                color: AppColors.onNavy,
                letterSpacing: 1.0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Shadow',
              style: GoogleFonts.tajawal(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                color: AppColors.terracotta,
                letterSpacing: 3.0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              'مرافقك الأكاديمي الذكي',
              style: GoogleFonts.tajawal(
                fontSize: 17.0,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedOnNavy,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
