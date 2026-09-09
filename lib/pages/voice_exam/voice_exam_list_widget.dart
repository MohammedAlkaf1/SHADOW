// Entry screen for the voice-driven exam feature (physical/motor-impairment
// mode, task 1): loads the student's available exams and always shows the
// picker — even when there's only one exam. Selecting one goes through an
// explicit confirm-before-start gate (voice_exam_confirm_widget.dart), never
// straight into the question flow. See lib/services/platform_client.dart's
// getAvailableExams (GET /api/student/exams) and voice_exam_session_widget.dart
// for the actual question-answering flow.

import '/a11y.dart';
import '/theme.dart';
import '/services/exam_models.dart';
import '/services/platform_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'voice_exam_confirm_widget.dart';

class VoiceExamListWidget extends StatefulWidget {
  const VoiceExamListWidget({super.key});

  @override
  State<VoiceExamListWidget> createState() => _VoiceExamListWidgetState();
}

class _VoiceExamListWidgetState extends State<VoiceExamListWidget> {
  bool _loading = true;
  String? _error;
  List<ExamSummary> _exams = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await PlatformClient.getAvailableExams();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
      return;
    }
    setState(() {
      _loading = false;
      _exams = result.data;
    });
  }

  /// Never enters the question flow directly, regardless of how many exams
  /// are available — always routes through the explicit confirm-before-start
  /// gate first. Uses push (not pushReplacement) so "إلغاء" on the confirm
  /// screen returns cleanly to this list.
  void _openExam(ExamSummary exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceExamConfirmWidget(exam: exam),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        18.0, AppSpacing.md, 18.0, 14.8),
                    child: Row(
                      children: [
                        // Back button is rightmost per the Figma header
                        // (node 46:1327) — first in this RTL Row renders
                        // at the row's start (right).
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
                              icon: appBackIcon(context,
                                  color: AppColors.mutedOnCream, size: 20.0),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          // "الإعاقة الحركية" — Figma collapses the old
                          // single-button mode landing page (physical
                          // mode) and this exam list into one screen;
                          // reuses the same label Home's card uses.
                          child: Text('home.servicePhysicalTitle'.tr(),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.custom(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.45,
                                  color: AppColors.onCream)),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.8, color: AppColors.border),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.terracotta),
              const SizedBox(height: AppSpacing.md),
              Text('voiceExam.loadingExams'.tr(), style: AppText.body()),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40.0),
              const SizedBox(height: AppSpacing.md),
              Text(_error!, textAlign: TextAlign.center, style: AppText.body()),
              const SizedBox(height: AppSpacing.md),
              a11yButton(
                label: 'voiceExam.retry'.tr(),
                child: ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    minimumSize: const Size(140.0, AppSpacing.minTap),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0)),
                  ),
                  child: Text('voiceExam.retry'.tr(),
                      style: AppText.button(color: AppColors.cream)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.mutedOnCream, size: 40.0),
              const SizedBox(height: AppSpacing.md),
              Text('voiceExam.noExamsAvailable'.tr(),
                  textAlign: TextAlign.center,
                  style: AppText.body(color: AppColors.onCream)),
              const SizedBox(height: AppSpacing.xs),
              Text('voiceExam.noExamsAvailableHint'.tr(),
                  textAlign: TextAlign.center, style: AppText.label()),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _examCard(_exams[index]),
    );
  }

  Widget _examCard(ExamSummary exam) {
    final statusLabel = exam.isCompleted
        ? 'voiceExam.statusCompleted'.tr()
        : (exam.submissionStatus == 'in_progress'
            ? 'voiceExam.statusInProgress'.tr()
            : 'voiceExam.statusNotStarted'.tr());
    final ctaLabel = exam.isCompleted
        ? 'voiceExam.reviewCompleted'.tr()
        : (exam.submissionStatus == 'in_progress'
            ? 'voiceExam.resumeExam'.tr()
            : 'voiceExam.startExam'.tr());

    final statusColor = exam.isCompleted ? AppColors.success : AppColors.terracotta;

    return a11yButton(
      label: '${exam.title} — $statusLabel',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openExam(exam),
          child: Container(
            padding: const EdgeInsets.all(16.8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: EchoColors.shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title,
                    textAlign: TextAlign.start,
                    style: AppText.custom(
                        fontSize: 16, fontWeight: FontWeight.w800, height: 1.5, color: AppColors.onCream)),
                const SizedBox(height: 2.0),
                Text(
                    '${exam.courseCode} · ${'voiceExam.questionsCount'.tr(args: [
                          '${exam.questionCount}'
                        ])}',
                    textAlign: TextAlign.start,
                    style: AppText.custom(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        color: AppColors.mutedOnCream)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(ctaLabel,
                        style: AppText.custom(
                            fontSize: 13, fontWeight: FontWeight.w700, height: 1.5, color: AppColors.mutedOnCream)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6.0),
                          Text(statusLabel,
                              style: AppText.custom(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
