// Platform login screen — new in the platform-integration phase. Not a
// FlutterFlow-generated page (no _model.dart), kept as a single
// self-contained StatefulWidget since it's a simple form.
//
// On success: fetches the student's platform profile/directives, hydrates
// StudentProfileProvider via applyPlatformProfile, starts the usage-event
// auto-flush timer, then navigates to the mode-selection screen.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/platform_client.dart';
import '/student/student_profile_provider.dart';
import '/theme.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final loginResult = await PlatformClient.login(
      email,
      password,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;

    if (!loginResult.isSuccess) {
      setState(() {
        _loading = false;
        _error = loginResult.errorMessage;
      });
      return;
    }

    // Hydrate the student profile/directives right away so the mode
    // selection screen has accurate gating from the first frame. A failure
    // here still lets the student in — getStudentProfile() itself falls
    // back to cache, and if there's truly nothing yet, the app just shows
    // the local-default profile until the next successful fetch.
    final profileResult = await PlatformClient.getStudentProfile();
    if (mounted && profileResult.isSuccess) {
      context.read<StudentProfileProvider>().applyPlatformProfile(
            enabledTools: profileResult.data.enabledTools,
            directives: profileResult.data.directives,
          );
    }
    PlatformClient.startAutoFlushTimer();

    if (!mounted) return;
    setState(() => _loading = false);
    context.go(WelcomeSelectionWidget.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ش',
                        style: AppText.display(color: AppColors.terracotta)
                            .copyWith(fontSize: 36.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: AppText.title(color: AppColors.onCream),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'سجّل الدخول بحساب منصة شادو الخاص بك',
                    textAlign: TextAlign.center,
                    style: AppText.label(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _field(
                    label: 'البريد الإلكتروني',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    label: 'كلمة المرور',
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  a11yButton(
                    label: 'تذكرني',
                    child: InkWell(
                      onTap: () =>
                          setState(() => _rememberMe = !_rememberMe),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.terracotta,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? true),
                            ),
                            Text('تذكرني', style: AppText.body()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppText.label(color: AppColors.terracotta),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  a11yButton(
                    label: 'تسجيل الدخول',
                    child: SizedBox(
                      height: AppSpacing.minTap,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.pill),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text('دخول', style: AppText.button()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label()),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textDirection: ui.TextDirection.ltr,
          style: AppText.body(color: AppColors.onCream),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.terracotta),
            ),
          ),
        ),
      ],
    );
  }
}
