import '/a11y.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/theme.dart';
import 'dart:ui' as ui;
import '/custom_code/actions/index.dart' as actions;
import '/pages/consent/consent_screen.dart';
import '/services/app_prefs.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'physical_assistance_mode_model.dart';
export 'physical_assistance_mode_model.dart';

class PhysicalAssistanceModeWidget extends StatefulWidget {
  const PhysicalAssistanceModeWidget({super.key});

  static String routeName = 'PhysicalAssistanceMode';
  static String routePath = '/physicalAssistanceMode';

  @override
  State<PhysicalAssistanceModeWidget> createState() =>
      _PhysicalAssistanceModeWidgetState();
}

class _PhysicalAssistanceModeWidgetState
    extends State<PhysicalAssistanceModeWidget> {
  late PhysicalAssistanceModeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // The student's chosen quick-contact number (local only). Null until set.
  String? _quickContactNumber;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PhysicalAssistanceModeModel());
    AppPrefs.getQuickContactNumber().then((value) {
      if (mounted) safeSetState(() => _quickContactNumber = value);
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textAlign: TextAlign.end,
            style: AppText.body(color: AppColors.onNavy)),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleVoiceCommand() async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    safeSetState(() => _model.isListeningForCommand = true);
    final command = await actions.listenForVoiceCommand();
    safeSetState(() {
      _model.isListeningForCommand = false;
      if (command.isNotEmpty) _model.lastVoiceCommand = command;
    });

    if (command.isEmpty) return;

    // Intensive support: confirm the captured command before acting on it,
    // since misrecognition is costlier for this group. Light/moderate keep
    // executing immediately, as before.
    if (StudentProfile.current.isIntensive) {
      if (!mounted) return;
      final confirmed = await _confirmVoiceCommand(command);
      if (!confirmed) return;
    }

    _dispatchVoiceCommand(command);
  }

  void _dispatchVoiceCommand(String command) {
    if (command.contains('الصمم') || command.contains('صمم')) {
      context.pushNamed('DeafModeTranscription');
    } else if (command.contains('البصري') || command.contains('بصري')) {
      context.pushNamed('VisualAssistanceMode');
    } else if (command.contains('التعلم') || command.contains('تعلم')) {
      context.pushNamed('LearningSupportMode');
    } else if (command.contains('ارجع') ||
        command.contains('رجع') ||
        command.contains('رئيسي')) {
      context.pop();
    } else if (command.contains('اتصل') || command.contains('مساعد')) {
      _quickContact();
    }
  }

  /// "سمعتك تقول: [النص]. تنفيذ؟" confirmation card for intensive support.
  Future<bool> _confirmVoiceCommand(String command) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
          title: Text('تأكيد الأمر',
              textAlign: TextAlign.end, style: AppText.title()),
          content: Text('سمعتك تقول: "$command". تنفيذ؟',
              textAlign: TextAlign.end, style: AppText.body()),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('إلغاء',
                  style: AppText.button(color: AppColors.navy)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: AppColors.onNavy,
                minimumSize: const Size(140.0, AppSpacing.minTap + 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child:
                  Text('تنفيذ', style: AppText.button(color: AppColors.onNavy)),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Quick contact: dial the student's saved number. If none is set yet, prompt
  /// them to add one first. NOT an emergency service — a student-set number.
  Future<void> _quickContact() async {
    final number = _quickContactNumber;
    if (number == null || number.isEmpty) {
      final added = await _editQuickContactDialog();
      if (added == null || added.isEmpty) return;
      await _dial(added);
      return;
    }
    await _dial(number);
  }

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _snack('تعذّر بدء الاتصال بالرقم $number');
    }
  }

  /// Add or edit the quick-contact number. Returns the saved number, or null.
  Future<String?> _editQuickContactDialog() async {
    final controller = TextEditingController(text: _quickContactNumber ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: Text('رقم الاتصال السريع',
              textAlign: TextAlign.end, style: AppText.title()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'أدخل رقم الشخص الذي تريد الاتصال به بسرعة (مثل مرافق أو أحد أفراد العائلة). يُحفظ على جهازك فقط.',
                textAlign: TextAlign.end,
                style: AppText.label(color: AppColors.onCream),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.end,
                autofocus: true,
                style: AppText.body(color: AppColors.onCream),
                cursorColor: AppColors.terracotta,
                decoration: InputDecoration(
                  hintText: '05xxxxxxxx',
                  hintStyle: AppText.body(color: AppColors.mutedOnCream),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.navy, width: 2.0)),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text('إلغاء', style: AppText.button(color: AppColors.navy)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.onNavy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () {
                final value = controller.text.trim();
                Navigator.pop(dialogContext, value.isEmpty ? null : value);
              },
              child: Text('حفظ', style: AppText.button(color: AppColors.onNavy)),
            ),
          ],
        ),
      ),
    );

    if (saved != null && saved.isNotEmpty) {
      await AppPrefs.setQuickContactNumber(saved);
      if (mounted) safeSetState(() => _quickContactNumber = saved);
    }
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the debug Developer Tools screen changes the active
    // profile, so a manual level switch (confirmation card / FAB size) is
    // reflected immediately without leaving and re-entering this screen.
    context.watch<StudentProfileProvider>();
    final listening = _model.isListeningForCommand;
    final commands = <({String label, IconData icon})>[
      (label: 'افتح وضع الصمم', icon: Icons.hearing_rounded),
      (label: 'افتح وضع البصرية', icon: Icons.visibility_rounded),
      (label: 'افتح وضع التعلم', icon: Icons.psychology_rounded),
      (label: 'ارجع للرئيسية', icon: Icons.home_rounded),
      (label: 'اتصل بجهة الاتصال السريع', icon: Icons.phone_rounded),
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.cream,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        // Quick-contact size grows with support level: normal / +30% / +60%
        // — a bigger, easier-to-hit target for students who need it most.
        floatingActionButton: a11yButton(
          label: 'اتصال سريع',
          hint: _quickContactNumber == null
              ? 'لم يتم تعيين رقم بعد، اضغط للإضافة'
              : 'اتصال بالرقم المحفوظ',
          child: Transform.scale(
            scale: switch (StudentProfile.current.supportLevel) {
              SupportLevel.light => 1.0,
              SupportLevel.moderate => 1.3,
              SupportLevel.intensive => 1.6,
            },
            child: FloatingActionButton.extended(
              onPressed: _quickContact,
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.onNavy,
              icon: const Icon(Icons.phone_rounded, color: AppColors.onNavy),
              label: Text('اتصال سريع',
                  style: AppText.button(color: AppColors.onNavy)),
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: AppColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                    child: Row(
                      children: [
                        a11yButton(
                          label: 'رجوع',
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 48.0,
                            fillColor: Colors.transparent,
                            icon: appBackIcon(context),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        Expanded(
                          child: Text('التحكم بالصوت',
                              textAlign: TextAlign.end, style: AppText.title()),
                        ),
                        a11yButton(
                          label: 'تعيين رقم الاتصال السريع',
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 48.0,
                            fillColor: Colors.transparent,
                            icon: const Icon(Icons.contact_phone_outlined,
                                color: AppColors.mutedOnCream, size: 24.0),
                            onPressed: _editQuickContactDialog,
                          ),
                        ),
                      ].divide(const SizedBox(width: AppSpacing.sm)),
                    ),
                  ),
                  Container(height: 1.0, color: AppColors.border),
                ],
              ),
            ),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Voice command display
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 80.0),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(
                          color: listening
                              ? AppColors.terracotta
                              : AppColors.border,
                          width: 2.0,
                        ),
                      ),
                      child: a11yLive(Text(
                        listening
                            ? '🎙 جارٍ الاستماع...'
                            : (_model.lastVoiceCommand ?? 'انتظار الأمر الصوتي'),
                        textAlign: TextAlign.center,
                        style: AppText.body(
                            color: listening
                                ? AppColors.terracotta
                                : AppColors.mutedOnCream),
                      )),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Big mic button
                    Center(
                      child: a11yButton(
                        label: listening
                            ? 'جارٍ الاستماع'
                            : 'اضغط وتكلم لإعطاء أمر صوتي',
                        enabled: !listening,
                        child: GestureDetector(
                          onTap: listening ? null : _handleVoiceCommand,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 140.0,
                            height: 140.0,
                            decoration: BoxDecoration(
                              color: listening
                                  ? AppColors.terracotta
                                  : AppColors.navy,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (listening
                                          ? AppColors.terracotta
                                          : AppColors.navy)
                                      .withValues(
                                          alpha: listening ? 0.5 : 0.3),
                                  blurRadius: 24.0,
                                  spreadRadius: listening ? 8.0 : 0.0,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: listening
                                ? const SizedBox(
                                    width: 52.0,
                                    height: 52.0,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 3.0,
                                        color: AppColors.onNavy),
                                  )
                                : const Icon(Icons.mic_rounded,
                                    color: AppColors.onNavy, size: 64.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      listening ? 'جارٍ الاستماع...' : 'اضغط وتكلم',
                      textAlign: TextAlign.center,
                      style: AppText.title(
                          color: listening
                              ? AppColors.terracotta
                              : AppColors.onCream),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Commands section
                    Text('الأوامر المدعومة',
                        textAlign: TextAlign.end,
                        style: AppText.body(color: AppColors.onCream)),
                    const SizedBox(height: AppSpacing.md),
                    ...commands.map(
                      (cmd) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.md),
                          decoration: AppDecor.creamCard(),
                          child: Row(
                            children: [
                              Icon(cmd.icon,
                                  color: AppColors.navy, size: 22.0),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text('"${cmd.label}"',
                                    textAlign: TextAlign.end,
                                    style:
                                        AppText.body(color: AppColors.onCream)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
