// Explicit confirm-before-start gate for the voice-driven exam feature:
// after picking an exam from the list, the student must explicitly confirm
// — by TAP ONLY — before the question flow actually begins. No path skips
// this screen, even when the list has only one exam.
//
// Deliberately tap-only, not voice: voice input in this feature is reserved
// for answering exam questions, not for navigating to/confirming the exam
// itself (a change from an earlier version that also listened for spoken
// "نعم"/"إعادة" here — removed at the user's explicit request, and as a
// side benefit it also removes a real flakiness source: ambient room noise
// could get misclassified as a spoken reply and silently cancel or confirm
// on its own).

import '/a11y.dart';
import '/theme.dart';
import '/services/exam_models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'voice_exam_session_widget.dart';

class VoiceExamConfirmWidget extends StatelessWidget {
  const VoiceExamConfirmWidget({super.key, required this.exam});

  final ExamSummary exam;

  void _confirm(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VoiceExamSessionWidget(exam: exam)),
    );
  }

  void _cancel(BuildContext context) {
    Navigator.of(context).pop();
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
                        a11yButton(
                          label: 'voiceExam.confirmStartCancel'.tr(),
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
                              onPressed: () => _cancel(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text('voiceExam.confirmStartTitle'.tr(),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: EchoColors.shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38.0,
                            height: 38.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.terracotta, width: 1.6),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.question_mark_rounded,
                                color: AppColors.terracotta, size: 20.0),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          a11yLive(Text(
                            'voiceExam.confirmStartTemplate'.tr(args: [exam.title]),
                            textAlign: TextAlign.start,
                            style: AppText.custom(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.75,
                                color: AppColors.onCream),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    a11yButton(
                      label: 'voiceExam.confirmStartYes'.tr(),
                      child: Material(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(16.0),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _confirm(context),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 56.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.terracotta.withValues(alpha: 0.55),
                                  blurRadius: 9.0,
                                  offset: const Offset(0, 8.0),
                                ),
                              ],
                            ),
                            child: Text('voiceExam.confirmStartYes'.tr(),
                                style: AppText.button(color: const Color(0xFFF7F3EC))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    a11yButton(
                      label: 'voiceExam.confirmStartCancel'.tr(),
                      child: Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _cancel(context),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 56.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(color: AppColors.border, width: 0.8)),
                            child: Text('voiceExam.confirmStartCancel'.tr(),
                                style: AppText.button(color: AppColors.onCream)),
                          ),
                        ),
                      ),
                    ),
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
}
