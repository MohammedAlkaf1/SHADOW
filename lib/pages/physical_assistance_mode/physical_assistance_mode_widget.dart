import '/a11y.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/theme.dart';
import '/services/mentor_triggers.dart';
import '/services/platform_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '/pages/voice_exam/voice_exam_list_widget.dart';
import 'physical_assistance_mode_model.dart';
export 'physical_assistance_mode_model.dart';

/// This mode's screen is deliberately reduced to a single entry point — the
/// fully voice-driven exam flow. The general voice-command navigation (mic
/// button, "الأوامر المدعومة" list, quick-contact calling) that used to live
/// here was removed at the user's explicit request: this screen now does
/// exactly one thing.
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PhysicalAssistanceModeModel());
    MentorTriggers.incrementModeOpen('physical');
    PlatformClient.queueUsageEvent('mode_opened',
        payload: {'mode': 'physical'});
  }

  @override
  void dispose() {
    PlatformClient.flushQueuedEvents();
    _model.dispose();
    super.dispose();
  }

  void _openVoiceExam() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VoiceExamListWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.cream,
      // Custom header (not a real AppBar) — without SafeArea it renders
      // under the status bar, clipping the top of the page title.
      body: SafeArea(
        child: Column(
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
                          label: 'common.back'.tr(),
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 48.0,
                            fillColor: Colors.transparent,
                            icon: appBackIcon(context),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        Expanded(
                          child: Text('physical.title'.tr(),
                              textAlign: TextAlign.start, style: AppText.title()),
                        ),
                      ].divide(const SizedBox(width: AppSpacing.sm)),
                    ),
                  ),
                  Container(height: 1.0, color: AppColors.border),
                ],
              ),
            ),
            // Body — just the voice-exam entry point.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    _voiceExamButton(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceExamButton() {
    return a11yButton(
      label: 'physical.voiceExamButton'.tr(),
      hint: 'physical.voiceExamSub'.tr(),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openVoiceExam,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64.0),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: EchoColors.iconTile,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.quiz_rounded,
                      color: EchoColors.iconGlyph, size: 20.0),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('physical.voiceExamButton'.tr(),
                          textAlign: TextAlign.start,
                          style: AppText.custom(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              color: AppColors.onCream)),
                      const SizedBox(height: 2.0),
                      Text('physical.voiceExamSub'.tr(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
