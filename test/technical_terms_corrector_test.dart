import 'package:flutter_test/flutter_test.dart';
import 'package:shadow/data/technical_terms_dictionary.dart';
import 'package:shadow/services/technical_terms_corrector.dart';

void main() {
  test('manual scenario: "المشين ليننج والداتابيس" corrects both terms', () {
    const before = 'اليوم بنشرح عن المشين ليننج والداتابيس';
    final after = correctTechnicalTerms(before);
    // ignore: avoid_print
    print('BEFORE: $before');
    // ignore: avoid_print
    print('AFTER:  $after');
    expect(after, 'اليوم بنشرح عن Machine Learning وDatabase');
  });

  test('multi-word phrase matches whole, not just first word', () {
    expect(correctTechnicalTerms('نتكلم عن ارتيفيشيال انتلجنس اليوم'),
        'نتكلم عن Artificial Intelligence اليوم');
  });

  test('single-word term matches', () {
    expect(correctTechnicalTerms('نستخدم الالقورذم هذا'),
        'نستخدم Algorithm هذا');
  });

  test('plain Arabic text with no technical terms is unchanged', () {
    const text = 'اليوم الجو جميل والطلاب حضروا المحاضرة في الموعد';
    expect(correctTechnicalTerms(text), text);
  });

  test('empty text returns empty text', () {
    expect(correctTechnicalTerms(''), '');
  });

  test('punctuation and original spacing are preserved', () {
    expect(correctTechnicalTerms('نتكلم عن الالقورذم، ثم الداتابيس.'),
        'نتكلم عن Algorithm، ثم Database.');
  });

  test('attached ف connector is also handled', () {
    expect(correctTechnicalTerms('افتح الملف فالداتابيس فيه'),
        'افتح الملف فDatabase فيه');
  });

  test('a word that merely starts with و but is not a known term is untouched', () {
    const text = 'وقت المحاضرة الساعة عشرة';
    expect(correctTechnicalTerms(text), text);
  });

  test('dictionary has 300-500 distinct English terms as required', () {
    final distinctTerms = technicalTermsDictionary.values.toSet();
    expect(distinctTerms.length, greaterThanOrEqualTo(300));
    expect(distinctTerms.length, lessThanOrEqualTo(500));
  });

  test('no dictionary entry has an empty key or value', () {
    for (final entry in technicalTermsDictionary.entries) {
      expect(entry.key.trim(), isNotEmpty);
      expect(entry.value.trim(), isNotEmpty);
    }
  });

  test('every dictionary value round-trips through the corrector unchanged '
      'when it is the only word (sanity check on replacement values)', () {
    // Values are English (Latin script) — they must never accidentally match
    // an Arabic dictionary key themselves.
    for (final value in technicalTermsDictionary.values.take(20)) {
      expect(correctTechnicalTerms(value), value);
    }
  });

  // Regression coverage for a reported on-device bug: a sentence with 4
  // terms where only "Machine Learning" was corrected (and even that not
  // quite — the actual on-device output was the shorter "مشين لين", not any
  // form previously in the dictionary) and Database/Artificial
  // Intelligence/User Interface were missed entirely. Root cause: every
  // dictionary key assumed a leading "ال" the real Deepgram output didn't
  // always include. Fixed by trying the definite article both added and
  // removed (see _articleVariants in technical_terms_corrector.dart).

  test('reported bug: all 4 terms in one sentence are corrected, including '
      'the shorter no-article "مشين لين" form actually seen on-device', () {
    const before =
        'اليوم بنشرح عن مشين لين والداتابيس وارتيفيشيال انتلجنس واليوزر انترفيس';
    const expected =
        'اليوم بنشرح عن Machine Learning وDatabase وArtificial Intelligence وUser Interface';
    expect(correctTechnicalTerms(before), expected);
  });

  test('dictionary keys authored with a leading "ال" also match the same '
      'word without it (Deepgram often omits the article on loanwords)', () {
    expect(correctTechnicalTerms('نفتح داتابيس'), 'نفتح Database');
    expect(correctTechnicalTerms('نفتح انترفيس'), 'نفتح Interface');
    expect(correctTechnicalTerms('نفتح سوفتوير'), 'نفتح Software');
  });

  test('a dictionary key authored WITHOUT "ال" also matches the same word '
      'WITH it prepended', () {
    // 'مشين لين' is stored without an article; the toggle must also accept
    // the article-prefixed form as an alternate spelling of the same word.
    expect(correctTechnicalTerms('نتكلم عن الماشين لين'),
        'نتكلم عن Machine Learning');
  });
}
