import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go(WelcomeSelectionWidget.routePath);
      }
    });
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
