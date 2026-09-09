// The voice-driven exam-taking flow itself (tasks 2 and 3): shows each
// question and its options as text (the student reads them on-screen — no
// audio read-aloud, see the doc comment below on why), listens for the
// student's spoken answer (Deepgram, same service as deaf mode),
// fuzzy-matches it against the option texts, then shows a mandatory
// "فهمت: [الخيار] — صحيح؟" text confirmation and waits for a spoken
// "نعم"/"إعادة" before submitting and auto-advancing — with a manual button
// for every step too (never voice-only), per task 3's accessibility
// requirement.
//
// No TTS anywhere in this screen, deliberately: the question/options/
// confirmation text is always fully visible, and the student answers by
// voice — there is nothing for the app itself to read aloud. This replaced
// an earlier design (read-preference screen + Gemini TTS proxy calls) that
// added real-world failure modes (TTS daily quota, latency, billing) for a
// feature that was pure convenience once the text was already on screen.
// See platform_client.dart's history for the removed synthesizeSpeech
// method and PlatformClient's /tts/generate call — deliberately not touched
// on the platform side in case other features still use that endpoint.
//
// State machine (see _Phase): loadingQuestions -> (per question)
// listeningAnswer -> [noMatch -> listeningAnswer]* -> confirming ->
// submitting -> (next question, or finished).

import 'dart:typed_data';

import '/a11y.dart';
import '/theme.dart';
import '/custom_code/actions/listen_for_exam_answer.dart';
import '/services/exam_answer_matcher.dart';
import '/services/exam_models.dart';
import '/services/platform_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum _Phase {
  loadingQuestions,
  errorLoadingQuestions,
  listeningAnswer,
  noMatch,
  confirming,
  submitting,
  submitError,
  finished,
}

class VoiceExamSessionWidget extends StatefulWidget {
  const VoiceExamSessionWidget({super.key, required this.exam});

  /// The summary the student picked from the list — already has enough
  /// (id/title) to start; the full question set is fetched in initState.
  final ExamSummary exam;

  @override
  State<VoiceExamSessionWidget> createState() => _VoiceExamSessionWidgetState();
}

class _VoiceExamSessionWidgetState extends State<VoiceExamSessionWidget> {
  _Phase _phase = _Phase.loadingQuestions;
  ExamDetail? _detail;
  int _index = 0;
  String _lastHeard = '';
  ExamOption? _matchedOption;
  String? _errorMessage;
  ExamResult? _result;
  bool _resultLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  ExamQuestion get _currentQuestion => _detail!.questions[_index];

  Future<void> _loadQuestions() async {
    setState(() => _phase = _Phase.loadingQuestions);
    final result = await PlatformClient.getExamQuestions(widget.exam.id);
    if (!mounted) return;
    if (!result.isSuccess || result.data.questions.isEmpty) {
      setState(() {
        _phase = _Phase.errorLoadingQuestions;
        _errorMessage = result.isSuccess
            ? 'voiceExam.errorLoadingQuestions'.tr()
            : result.errorMessage;
      });
      return;
    }
    setState(() {
      _detail = result.data;
      _index = 0;
    });
    _startQuestion();
  }

  /// Shows the question/options (already rendered by _questionFlow the
  /// instant _phase changes) and opens the mic immediately — no TTS, no
  /// wait of any kind between the question appearing and the mic listening.
  void _startQuestion() {
    if (!mounted) return;
    setState(() {
      _matchedOption = null;
      _lastHeard = '';
    });
    _listenForAnswer();
  }

  Future<void> _listenForAnswer() async {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.listeningAnswer;
      _matchedOption = null;
    });

    final capture = await listenForExamAnswer();
    if (!mounted) return;
    setState(() => _lastHeard = capture.transcript);

    final match = matchSpokenAnswer(capture.transcript, _currentQuestion.options);
    if (match == null) {
      setState(() => _phase = _Phase.noMatch);
      _listenForAnswer();
      return;
    }

    setState(() {
      _matchedOption = match;
      _phase = _Phase.confirming;
    });
    _confirmLoop();
  }

  /// Shows "فهمت: [الخيار] — صحيح؟" as text only (see _statusText's
  /// confirming case) and listens for a spoken "نعم"/"إعادة" — no TTS reads
  /// this prompt aloud; the student reads it and answers by voice.
  Future<void> _confirmLoop() async {
    if (!mounted || _matchedOption == null) return;

    final capture = await listenForExamAnswer(maxDuration: const Duration(seconds: 8));
    if (!mounted) return;
    setState(() => _lastHeard = capture.transcript);

    final reply = classifyConfirmReply(capture.transcript);
    switch (reply) {
      case ConfirmReply.yes:
      case ConfirmReply.nextQuestion:
        await _submitAndAdvance(capture.audioWav);
        break;
      case ConfirmReply.repeatQuestion:
        _startQuestion();
        break;
      case ConfirmReply.retry:
        _listenForAnswer();
        break;
      case ConfirmReply.unknown:
        // Didn't catch a clear yes/retry — ask again rather than guessing.
        _confirmLoop();
        break;
    }
  }

  /// [confirmationAudio] is null for the manual "نعم، تأكيد"/submit-error-retry
  /// paths (no real clip exists to send) — deliberately NOT an empty
  /// Uint8List. The server's upsert only overwrites a question's stored
  /// voiceConfirmationObjectKey when a file is actually present in the
  /// request; sending an empty-but-non-null file previously meant a manual
  /// button tap could silently wipe out a real, already-uploaded voice
  /// clip from an earlier genuine attempt at the same question.
  Future<void> _submitAndAdvance(Uint8List? confirmationAudio) async {
    if (!mounted || _matchedOption == null) return;
    debugPrint('🔊 _submitAndAdvance: confirmationAudio=${confirmationAudio == null ? 'null (manual/no clip)' : '${confirmationAudio.length} bytes (real captured clip)'}');
    setState(() => _phase = _Phase.submitting);

    final result = await PlatformClient.submitExamAnswer(
      examId: widget.exam.id,
      questionId: _currentQuestion.id,
      selectedOptionId: _matchedOption!.id,
      confirmationAudioWav: confirmationAudio,
    );
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _phase = _Phase.submitError;
        _errorMessage = result.errorMessage;
      });
      return;
    }

    if (_index + 1 < _detail!.questions.length) {
      setState(() => _index += 1);
      _startQuestion();
    } else {
      setState(() => _phase = _Phase.finished);
      _loadResult();
    }
  }

  /// Called once, right after the last answer is submitted. Gated
  /// server-side on the faculty's Exam.showResultsToStudents opt-in (see
  /// GET /api/exams/:id/my-result's doc comment) — when unavailable,
  /// [_result] stays null and _finishedCard() shows the same neutral
  /// "تم التسليم" text it always did, with no hint a score exists at all.
  /// Shown as text only — no TTS, matching the rest of this screen.
  Future<void> _loadResult() async {
    setState(() => _resultLoading = true);
    final result = await PlatformClient.getExamResult(widget.exam.id);
    if (!mounted) return;
    setState(() {
      _resultLoading = false;
      _result = result.isSuccess ? result.data : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final total = _detail?.questions.length ?? 0;
    return Container(
      color: AppColors.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                18.0, AppSpacing.md, 18.0, 14.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button is rightmost per the Figma header (node
                // 46:1290) — first in this RTL Row renders at the row's
                // start (right).
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exam.title,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.45,
                            color: AppColors.onCream),
                      ),
                      if (total > 0 && _phase != _Phase.finished)
                        Text(
                          'voiceExam.questionProgress'.tr(args: ['${_index + 1}', '$total']),
                          textAlign: TextAlign.start,
                          style: AppText.custom(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: AppColors.mutedOnCream),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loadingQuestions:
        return _loadingCard('voiceExam.loadingQuestions'.tr());
      case _Phase.errorLoadingQuestions:
        return _errorCard(_errorMessage ?? 'voiceExam.errorLoadingQuestions'.tr(), _loadQuestions);
      case _Phase.finished:
        return _finishedCard();
      case _Phase.submitError:
        return _errorCard(
          _errorMessage ?? 'voiceExam.submitFailed'.tr(),
          () => _submitAndAdvance(null),
        );
      default:
        return _questionFlow();
    }
  }

  Widget _loadingCard(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.terracotta),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: AppText.body()),
        ],
      ),
    );
  }

  Widget _errorCard(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40.0),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: AppText.body()),
          const SizedBox(height: AppSpacing.md),
          a11yButton(
            label: 'voiceExam.retry'.tr(),
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                minimumSize: const Size(140.0, AppSpacing.minTap),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
              ),
              child: Text('voiceExam.retry'.tr(), style: AppText.button(color: AppColors.cream)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishedCard() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 88.0,
          height: 88.0,
          decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.check_rounded, color: AppColors.cream, size: 48.0),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('voiceExam.examSubmittedTitle'.tr(),
            textAlign: TextAlign.center,
            style: AppText.custom(
                fontSize: 22, fontWeight: FontWeight.w800, height: 1.4, color: AppColors.onCream)),
        const SizedBox(height: AppSpacing.sm),
        // Neutral by default — only ever mentions a score when the faculty
        // member explicitly opted in (Exam.showResultsToStudents); while
        // that's still loading, or when it's unavailable, this stays the
        // same "تم التسليم" text it always was, with no hint a score exists.
        if (_resultLoading)
          Text('voiceExam.resultLoading'.tr(),
              textAlign: TextAlign.center, style: AppText.body())
        else if (_result?.available == true)
          a11yLive(Text(
            'voiceExam.resultAvailableTemplate'.tr(
                args: ['${_result!.correctCount}', '${_result!.totalQuestions}']),
            textAlign: TextAlign.center,
            style: AppText.custom(
                fontSize: 18, fontWeight: FontWeight.w700, height: 1.4, color: AppColors.terracotta),
          ))
        else
          Text('voiceExam.examSubmittedBody'.tr(),
              textAlign: TextAlign.center, style: AppText.body()),
        const SizedBox(height: AppSpacing.xl),
        a11yButton(
          label: 'voiceExam.backToHome'.tr(),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              minimumSize: const Size.fromHeight(AppSpacing.minTap),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
            ),
            child: Text('voiceExam.backToHome'.tr(), style: AppText.button(color: AppColors.onNavy)),
          ),
        ),
      ],
    );
  }

  /// The main per-question card: question text (the only source of the
  /// question — no audio equivalent to fall back to), a live-region showing
  /// the last thing heard, state-specific status text, and manual button
  /// equivalents for every voice action — task 3's accessibility
  /// requirement, never voice-only.
  Widget _questionFlow() {
    final q = _currentQuestion;
    final listening = _phase == _Phase.listeningAnswer || _phase == _Phase.confirming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18.8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: EchoColors.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.text,
                  textAlign: TextAlign.start,
                  style: AppText.custom(
                      fontSize: 17, fontWeight: FontWeight.w800, height: 1.7, color: AppColors.onCream)),
              const SizedBox(height: AppSpacing.md),
              ...q.options.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _matchedOption?.id == o.id
                              ? AppColors.terracotta
                              : AppColors.mutedOnCream,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(o.text,
                            textAlign: TextAlign.start,
                            style: AppText.custom(
                                fontSize: 15,
                                fontWeight: _matchedOption?.id == o.id
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                height: 1.7,
                                color: _matchedOption?.id == o.id
                                    ? AppColors.terracotta
                                    : AppColors.onCream)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Status / live-region — what's happening + what was heard. The
        // stronger terracotta tint matches Figma's "confirming" state
        // exactly (node 46:1290); other phases keep the original neutral
        // styling since Figma has no reference for them.
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56.0),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _phase == _Phase.confirming
                ? AppColors.terracotta.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
                color: listening ? AppColors.terracotta : AppColors.border, width: 0.8),
          ),
          child: a11yLive(Text(
            _statusText(),
            textAlign: TextAlign.center,
            style: AppText.custom(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: listening ? AppColors.terracotta : AppColors.mutedOnCream),
          )),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._actionButtons(),
        const SizedBox(height: AppSpacing.md),
        Text('voiceExam.voiceNavHint'.tr(),
            textAlign: TextAlign.center, style: AppText.label()),
      ],
    );
  }

  String _statusText() {
    switch (_phase) {
      case _Phase.listeningAnswer:
        return 'voiceExam.listeningForAnswer'.tr();
      case _Phase.noMatch:
        return 'voiceExam.didNotUnderstand'.tr();
      case _Phase.confirming:
        return _matchedOption != null
            ? 'voiceExam.confirmQuestionTemplate'.tr(args: [_matchedOption!.text])
            : 'voiceExam.listeningForConfirmation'.tr();
      case _Phase.submitting:
        return 'voiceExam.submittingAnswer'.tr();
      default:
        return _lastHeard;
    }
  }

  /// Manual, ≥48×48 button equivalents for every voice action in this
  /// screen — task 3's explicit requirement that a student for whom
  /// speaking is easier than pressing still has buttons available, and
  /// vice versa for anyone whose motor control makes precise taps hard.
  List<Widget> _actionButtons() {
    switch (_phase) {
      case _Phase.listeningAnswer:
      case _Phase.noMatch:
        return [
          _actionButton(
            label: 'voiceExam.repeatQuestion'.tr(),
            color: AppColors.surface,
            textColor: AppColors.onCream,
            bordered: true,
            onTap: _startQuestion,
          ),
        ];
      case _Phase.confirming:
        return [
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'voiceExam.confirmYes'.tr(),
                  color: AppColors.terracotta,
                  accentShadow: true,
                  onTap: () => _submitAndAdvance(null),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _actionButton(
                  label: 'voiceExam.confirmRetry'.tr(),
                  color: AppColors.navy,
                  onTap: _listenForAnswer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _actionButton(
            label: 'voiceExam.repeatQuestion'.tr(),
            color: AppColors.surface,
            textColor: AppColors.onCream,
            bordered: true,
            onTap: _startQuestion,
          ),
        ];
      case _Phase.submitting:
        return [
          const SizedBox(
            height: AppSpacing.minTap,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _actionButton({
    required String label,
    required Color color,
    Color? textColor,
    bool bordered = false,
    bool accentShadow = false,
    required VoidCallback onTap,
  }) {
    return a11yButton(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: bordered ? Border.all(color: AppColors.border, width: 0.8) : null,
          boxShadow: accentShadow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 9.0,
                    offset: const Offset(0, 8.0),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56.0),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppText.button(color: textColor ?? const Color(0xFFF7F3EC))),
            ),
          ),
        ),
      ),
    );
  }
}
