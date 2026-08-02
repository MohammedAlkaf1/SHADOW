// Corrects Deepgram's Arabic phonetic transliteration of English academic/
// technical terms (e.g. "المشين ليننج") back to the correct English term
// ("Machine Learning"), using the dictionary in
// lib/data/technical_terms_dictionary.dart. Applied to live transcript text
// (deaf mode) and AI results that may contain technical terms (learning
// support mode) before either is shown or saved.
//
// Matching strategy: the transcript is split once into alternating
// whitespace / punctuation / word segments (a single regex pass, O(n) in
// input length). Only "word" segments are lookup candidates; whitespace and
// punctuation are carried through unchanged, so original spacing/newlines
// and punctuation marks survive untouched. For each word position, the
// longest possible phrase (bounded by the dictionary's own longest key, a
// small constant — currently 3 words) is tried first, then shorter phrases,
// down to a single word — so multi-word terms like "Machine Learning" are
// matched whole rather than only the first word. Every lookup is a plain
// Map hash lookup (O(1)); nothing scans the dictionary itself per word, so
// this stays fast regardless of dictionary size and safe to run on every
// live-transcript update.

import '/data/technical_terms_dictionary.dart';

// Not a raw string, so ء-ي (Arabic letters only — U+0621-U+064A) is
// interpreted by Dart into the actual characters at compile time, while
// \\s stays a literal backslash-s for the regex engine to read as
// "whitespace". Deliberately narrower than the full ؀-ۿ Arabic
// block: that block also contains Arabic punctuation (، ؛ ؟ at U+060C/
// U+061B/U+061F), which sit *below* U+0621 — using the full block would
// swallow a trailing "،" into the word itself and break dictionary lookups
// on punctuated text (caught by a unit test).
final RegExp _tokenPattern = RegExp(
  '(?<ws>\\s+)|(?<word>[ء-يa-zA-Z0-9]+)|'
  '(?<punct>[^\\sء-يa-zA-Z0-9]+)',
);

/// Longest phrase (in words) present as a dictionary key — computed once
/// from the dictionary itself so adding a longer phrase later doesn't
/// require touching this file.
final int _maxDictionaryPhraseWords = technicalTermsDictionary.keys
    .map((k) => ' '.allMatches(k).length + 1)
    .fold(1, (a, b) => a > b ? a : b);

/// Normalizes Arabic alef variants and strips tatweel so minor spelling
/// differences in how Deepgram renders hamza don't cause a missed match.
/// Deliberately conservative — this is the only normalization applied;
/// dictionary keys are authored already in this normalized form.
String _normalize(String s) => s
    .replaceAll('أ', 'ا')
    .replaceAll('إ', 'ا')
    .replaceAll('آ', 'ا')
    .replaceAll('ـ', '');

/// Arabic conjunctions attach directly to the next word with no space
/// ("والداتابيس", not "و الداتابيس") — including a code-switched term. Only
/// و (and) and ف (so/then) are stripped: they're unambiguous single-letter
/// connectors, and stripping only fires a match when the *remainder* is an
/// exact dictionary key, so this can't misfire on an ordinary Arabic word
/// that merely happens to start with the same letter.
const _attachableConnectors = ['و', 'ف'];

/// Replaces every recognized phonetic transliteration in [text] with its
/// correct English term. Text with no technical terms is returned unchanged
/// (including its exact original whitespace/punctuation).
String correctTechnicalTerms(String text) {
  if (text.isEmpty) return text;

  // Tokenize once: `segments` holds every whitespace/punctuation/word run in
  // order; `wordIndices` records which of those segments are words (lookup
  // candidates), so the two lists share a single pass over the input.
  final segments = <String>[];
  final wordIndices = <int>[];
  for (final match in _tokenPattern.allMatches(text)) {
    segments.add(match.group(0)!);
    if (match.namedGroup('word') != null) {
      wordIndices.add(segments.length - 1);
    }
  }

  var i = 0;
  while (i < wordIndices.length) {
    var matchedSpan = 0;
    for (var span = _maxDictionaryPhraseWords; span >= 1; span--) {
      if (i + span > wordIndices.length) continue;
      final words = [
        for (var k = 0; k < span; k++) segments[wordIndices[i + k]],
      ];
      final firstWord = _normalize(words.first);

      // Try the phrase as-is, then — only on the first word — with a
      // leading attached connector (و/ف) stripped, so "والداتابيس" still
      // matches the "الداتابيس" key; the connector is prepended to the
      // output with no space, matching how it was attached on input.
      String? replacement;
      String prefix = '';
      final direct = ([firstWord, ...words.skip(1).map(_normalize)]).join(' ');
      replacement = technicalTermsDictionary[direct];
      if (replacement == null) {
        for (final connector in _attachableConnectors) {
          if (!firstWord.startsWith(connector) || firstWord.length <= connector.length) {
            continue;
          }
          final stripped = firstWord.substring(connector.length);
          final withStripped =
              ([stripped, ...words.skip(1).map(_normalize)]).join(' ');
          final hit = technicalTermsDictionary[withStripped];
          if (hit != null) {
            replacement = hit;
            prefix = connector;
            break;
          }
        }
      }

      if (replacement != null) {
        segments[wordIndices[i]] = '$prefix$replacement';
        // Collapse the rest of the matched phrase: clear each subsequent
        // word and the whitespace segment immediately before it (the
        // separator that joined it to the previous word), so no double
        // spacing is left behind. Assumes words in a multi-word key are
        // separated by whitespace, not punctuation — true for spoken
        // transcripts.
        for (var k = 1; k < span; k++) {
          final wordIdx = wordIndices[i + k];
          segments[wordIdx] = '';
          segments[wordIdx - 1] = '';
        }
        matchedSpan = span;
        break;
      }
    }
    i += matchedSpan > 0 ? matchedSpan : 1;
  }

  return segments.join();
}
