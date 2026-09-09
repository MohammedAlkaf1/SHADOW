// Student profile detail screen — new page, not previously part of the app.
// Matches the approved Figma file (rSY5pDmqY1jctcNOBg7gPC, node 37:677,
// "الملف الشخصي"). Most of the academic fields Figma shows (student ID,
// university, department, year, academic advisor, assigned specialist,
// plan-approval status) have no real data source anywhere in this app today
// — there is no student directory or advisor-assignment API. Only two
// fields are real: the remembered login email, and the support level
// (StudentProfile.current.supportLevel.arabicLabel). The rest render as
// static placeholder text mirroring Figma's own sample content, clearly
// marked below, rather than silently inventing backend fields.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/a11y.dart';
import '/services/app_prefs.dart';
import '/student/student_profile.dart';
import '/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    AppPrefs.getSavedCredentials().then((creds) {
      if (mounted && creds != null) setState(() => _savedEmail = creds.$1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final supportLevel = context.locale.languageCode == 'ar'
        ? StudentProfile.current.supportLevel.arabicLabel
        : StudentProfile.current.supportLevel.englishLabel;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _identityCard(),
                    const SizedBox(height: 20.0),
                    _sectionLabel('profile.academicData'.tr()),
                    _card([
                      // Placeholder — no student-directory data source yet.
                      _row(value: '2021104', label: 'profile.studentId'.tr()),
                      _row(value: 'profile.universityValue'.tr(), label: 'profile.university'.tr()),
                      _row(value: 'profile.departmentValue'.tr(), label: 'profile.department'.tr()),
                      _row(value: 'profile.levelValue'.tr(), label: 'profile.level'.tr()),
                      _row(value: 'profile.advisorValue'.tr(), label: 'profile.advisor'.tr()),
                    ]),
                    const SizedBox(height: 20.0),
                    _sectionLabel('profile.support'.tr()),
                    _card([
                      // Real: StudentProfile.current.supportLevel.
                      _row(value: supportLevel, label: 'profile.supportLevel'.tr()),
                      // Placeholder — no specialist-assignment API yet.
                      _row(value: 'profile.specialistValue'.tr(), label: 'profile.specialist'.tr()),
                      _row(
                          value: 'profile.planStatusValue'.tr(),
                          label: 'profile.planStatus'.tr(),
                          valueColor: AppColors.success),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 12.0, 18.0, 14.8),
      child: Row(
        children: [
          a11yButton(
            label: 'common.back'.tr(),
            child: Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: EchoColors.shadow,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: appBackIcon(context, color: AppColors.mutedOnCream, size: 20.0),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('profile.title'.tr(),
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.custom(
                    fontSize: 19, fontWeight: FontWeight.w800, height: 1.45, color: AppColors.onCream)),
          ),
        ],
      ),
    );
  }

  Widget _identityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.8, vertical: 22.8),
      decoration: BoxDecoration(
        color: EchoColors.primaryBg,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: EchoColors.primaryShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64.0,
            height: 64.0,
            decoration: BoxDecoration(
              color: EchoColors.primaryText.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20.0),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person_rounded, size: 30.0, color: EchoColors.primaryBg),
          ),
          const SizedBox(height: 10.0),
          Text(_savedEmail?.split('@').first ?? 'app.title'.tr(),
              textAlign: TextAlign.center,
              style: AppText.custom(
                  fontSize: 19, fontWeight: FontWeight.w800, height: 1.4, color: EchoColors.primaryText)),
          if (_savedEmail != null) ...[
            const SizedBox(height: 2.0),
            Text(_savedEmail!,
                textAlign: TextAlign.center,
                style: AppText.custom(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: EchoColors.primaryText.withValues(alpha: 0.86))),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 8.0),
        child: Text(text,
            textAlign: TextAlign.end,
            style: AppText.custom(
                fontSize: 12, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.mutedOnCream)),
      );

  Widget _card(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: EchoColors.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 0.8, color: const Color(0xFFE4DFD4)),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row({required String value, required String label, Color? valueColor}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              textAlign: TextAlign.start,
              style: AppText.custom(
                  fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.mutedOnCream)),
          Text(value,
              textAlign: TextAlign.end,
              style: AppText.custom(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                  color: valueColor ?? AppColors.onCream)),
        ],
      ),
    );
  }
}
