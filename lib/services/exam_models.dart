// Data models for the voice-driven exam feature (physical/motor-impairment
// mode). Mirrors the exact JSON shapes returned by the platform's
// GET /api/student/exams and GET /api/exams/:id/questions — see
// PlatformClient's exam methods and D:\Shadow\platform's docs/API.md.
//
// Phase 1 scope: MCQ only (the platform's own QuestionType enum has no
// other value yet), so there's no branching on question type here.

/// One row from GET /api/student/exams — enough to list and pick an exam,
/// before fetching its full question set.
class ExamSummary {
  const ExamSummary({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.questionCount,
    required this.submissionStatus,
  });

  final String id;
  final String title;
  final String courseCode;
  final int questionCount;

  /// null = never started; otherwise "in_progress" or "completed" (the
  /// platform's ExamSubmissionStatus enum, passed through verbatim).
  final String? submissionStatus;

  bool get isCompleted => submissionStatus == 'completed';

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    final submission = json['submission'] as Map<String, dynamic>?;
    return ExamSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      courseCode: json['courseCode'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      submissionStatus: submission?['status'] as String?,
    );
  }
}

class ExamOption {
  const ExamOption({required this.id, required this.text, required this.order});

  final String id;
  final String text;
  final int order;

  factory ExamOption.fromJson(Map<String, dynamic> json) => ExamOption(
        id: json['id'] as String,
        text: json['text'] as String,
        order: json['order'] as int,
      );
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.text,
    required this.order,
    required this.options,
  });

  final String id;
  final String text;
  final int order;
  final List<ExamOption> options;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id'] as String,
        text: json['text'] as String,
        order: json['order'] as int,
        options: (json['options'] as List)
            .map((o) => ExamOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

/// GET /api/exams/:id/my-result's response — score is only ever populated
/// when [available] is true (the faculty member opted in via
/// Exam.showResultsToStudents); when false, the server deliberately omits
/// the score fields entirely rather than sending a null, so there's nothing
/// here to accidentally leak even on a client bug.
class ExamResult {
  const ExamResult({
    required this.available,
    this.score,
    this.correctCount,
    this.totalQuestions,
  });

  final bool available;
  final double? score;
  final int? correctCount;
  final int? totalQuestions;

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        available: json['available'] as bool? ?? false,
        score: (json['score'] as num?)?.toDouble(),
        correctCount: json['correctCount'] as int?,
        totalQuestions: json['totalQuestions'] as int?,
      );
}

/// The full response body of GET /api/exams/:id/questions — every question
/// fetched once up front (the endpoint isn't paginated per-question), then
/// walked through locally by the exam-taking screen.
class ExamDetail {
  const ExamDetail({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.questions,
  });

  final String id;
  final String title;
  final String courseCode;
  final List<ExamQuestion> questions;

  factory ExamDetail.fromJson(Map<String, dynamic> json) {
    final exam = json['exam'] as Map<String, dynamic>;
    return ExamDetail(
      id: exam['id'] as String,
      title: exam['title'] as String,
      courseCode: exam['courseCode'] as String,
      questions: (exam['questions'] as List)
          .map((q) => ExamQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
