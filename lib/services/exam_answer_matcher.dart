// Fuzzy-matches a Deepgram transcript of a spoken MCQ answer against the
// question's option texts (string_similarity, Dice's coefficient — see
// pubspec.yaml), and classifies short spoken replies during the mandatory
// "فهمت: ... — صحيح؟" confirmation step. Kept separate from the exam screen
// widget so the matching/classification logic can be read (and adjusted)
// without wading through UI code.

import 'package:string_similarity/string_similarity.dart';

import 'exam_models.dart';

/// Below this Dice's-coefficient score, a fuzzy match is not trusted even if
/// it was the "best" of the options — the caller should ask the student to
/// repeat instead of silently picking a low-confidence guess. Chosen low
/// (not 0.5+) because option texts are often short (a word or a number),
/// where Dice's coefficient (character-bigram overlap) naturally produces
/// lower absolute scores than it would for full sentences.
const double kExamAnswerMatchThreshold = 0.28;

/// Strips punctuation/diacritics noise Deepgram sometimes adds and
/// lower-cases Latin text, so "Option: four." and "four" compare fairly
/// against a plain option text of "Four". Arabic tatweel/diacritics are
/// stripped too, since spoken Arabic never surfaces them but a
/// faculty-authored option text occasionally does.
String normalizeForMatch(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[ً-ٰٟـ]'), ''); // diacritics + tatweel
  s = s.replaceAll(RegExp(r'[.,!?؟،؛:"‘’“”]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Picks the best-matching option for [transcript], or null if nothing
/// clears [kExamAnswerMatchThreshold]. Checks for an exact
/// contains-relationship first (common when the student says a full phrase
/// like "الخيار الثاني أربعة" and the option is just "أربعة", or vice versa)
/// before falling back to the fuzzy Dice's-coefficient score, since a
/// genuine substring match is a stronger signal than a similarity ratio on
/// short strings.
ExamOption? matchSpokenAnswer(String transcript, List<ExamOption> options) {
  if (options.isEmpty) return null;
  final normalizedTranscript = normalizeForMatch(transcript);
  if (normalizedTranscript.isEmpty) return null;

  for (final option in options) {
    final normalizedOption = normalizeForMatch(option.text);
    if (normalizedOption.isEmpty) continue;
    if (normalizedTranscript.contains(normalizedOption) ||
        normalizedOption.contains(normalizedTranscript)) {
      return option;
    }
  }

  final targets = options.map((o) => normalizeForMatch(o.text)).toList();
  final best = normalizedTranscript.bestMatch(targets);
  if ((best.bestMatch.rating ?? 0) >= kExamAnswerMatchThreshold) {
    return options[best.bestMatchIndex];
  }
  return null;
}

enum ConfirmReply { yes, retry, nextQuestion, repeatQuestion, unknown }

const _kNextQuestionPhrases = ['السؤال التالي', 'التالي', 'next question', 'next'];
const _kRepeatQuestionPhrases = ['أعد السؤال', 'اعد السؤال', 'كرر السؤال', 'repeat question'];
const _kYesWords = ['نعم', 'ايوه', 'أيوه', 'ايه', 'صحيح', 'صح', 'تمام', 'تأكيد', 'أكد', 'yes', 'yeah', 'correct', 'confirm'];
const _kRetryWords = ['إعادة', 'اعادة', 'لا', 'مو صحيح', 'مب صحيح', 'خطأ', 'no', 'repeat', 'again', 'wrong'];

/// Classifies a short spoken reply during the confirmation step. Checks the
/// two/three-word navigation phrases first — they're more specific than the
/// single-word yes/retry lists, so checking them first avoids e.g. "التالي"
/// ever being misread against a generic word list.
///
/// Single/short words (e.g. "لا") are matched as WHOLE WORDS in the
/// transcript, never as a raw substring — "لا" is a 2-character sequence
/// that appears embedded inside countless unrelated Arabic words ("الاول",
/// "لازم", "طلاب" ...), so naive `.contains()` produced false "إعادة"
/// matches on transcripts that never actually said "لا" at all (e.g. the
/// exam confirm screen auto-cancelling itself just from an exam titled
/// "الاول" being echoed back, or any ambient noise Deepgram loosely
/// transcribed). Multi-word phrases stay substring-matched since they're
/// long/specific enough not to collide with unrelated words.
ConfirmReply classifyConfirmReply(String transcript) {
  final normalized = normalizeForMatch(transcript);
  if (normalized.isEmpty) return ConfirmReply.unknown;
  final words = normalized.split(RegExp(r'\s+')).toSet();

  bool matchesAny(List<String> candidates) {
    for (final candidate in candidates) {
      final normalizedCandidate = normalizeForMatch(candidate);
      if (normalizedCandidate.contains(' ')) {
        if (normalized.contains(normalizedCandidate)) return true;
      } else {
        if (words.contains(normalizedCandidate)) return true;
      }
    }
    return false;
  }

  if (matchesAny(_kRepeatQuestionPhrases)) return ConfirmReply.repeatQuestion;
  if (matchesAny(_kNextQuestionPhrases)) return ConfirmReply.nextQuestion;
  if (matchesAny(_kRetryWords)) return ConfirmReply.retry;
  if (matchesAny(_kYesWords)) return ConfirmReply.yes;
  return ConfirmReply.unknown;
}
