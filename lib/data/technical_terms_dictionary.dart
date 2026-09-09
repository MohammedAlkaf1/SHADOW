// Dictionary of Arabic phonetic transliterations Deepgram is known to
// produce for English academic/technical terms spoken mid-sentence in
// Arabic — e.g. a student saying "Machine Learning" gets transcribed as
// "المشين ليننج" instead of being left in Latin script. correctTechnicalTerms()
// in lib/services/technical_terms_corrector.dart looks up substrings of the
// live transcript against this map and replaces a matched phonetic key with
// its correct English term before the text is shown or saved.
//
// ── How to add a new term ──────────────────────────────────────────────
// Add one line per phonetic variant, all pointing at the same English value:
//
//   'الفونيمي بالعربي': 'English Term',
//
// - Key: the Arabic phonetic transliteration exactly as Deepgram tends to
//   spell it (one or more words, separated by a single space — no leading
//   "ال" is required unless that's genuinely how it gets transcribed).
// - Value: the correct English term, capitalized as it should appear on
//   screen.
// - If the same term has more than one plausible phonetic spelling (e.g.
//   "Database" as "الداتابيس" or "الداتا بيز"), add one map entry per
//   variant — do not try to encode alternation inside a single key.
// - Keep keys free of diacritics and normalize alef forms to plain ا
//   (correctTechnicalTerms() normalizes the *input* text the same way
//   before lookup, so keys must already be in that normalized form).
// This map is intentionally flat and hand-authored for now; a future
// platform-managed version could load it from a server instead — the
// consuming function only depends on the Map<String, String> shape, not on
// this being a compile-time constant.
//
// ── Scope note (deliberately excluded, not an oversight) ───────────────
// Many medical and basic-science English terms have long-established,
// fully-native Arabic scientific vocabulary that Saudi students actually
// say instead of code-switching to English — virus/فيروس, bacteria/بكتيريا,
// hormone/هرمون, gene/جين, cell/خلية, atom/ذرة, molecule/جزيء, energy/طاقة,
// algorithm/خوارزمية, strategy/استراتيجية, and similar. A Deepgram
// transcription of the *Arabic* word for one of these is correct Arabic,
// not a phonetic error — including it here risked turning a correct Arabic
// sentence fragment into Latin-script English by mistake. These terms are
// deliberately left out of this dictionary; only medical/science terms that
// are actually commonly code-switched in spoken English were kept.

const Map<String, String> technicalTermsDictionary = {
  // ── Computer science, software engineering, AI ─────────────────────
  'القورذم': 'Algorithm',
  'الالقورذم': 'Algorithm',
  'الداتابيس': 'Database',
  'الداتا بيز': 'Database',
  'السوفتوير': 'Software',
  'السوفت وير': 'Software',
  'الهاردوير': 'Hardware',
  'الهارد وير': 'Hardware',
  'المشين ليرنينج': 'Machine Learning',
  'المشين ليننج': 'Machine Learning',
  'الماشين ليرنينج': 'Machine Learning',
  // Shorter form observed on-device: Deepgram dropped the "ر" of "learning"
  // and the article entirely.
  'مشين لين': 'Machine Learning',
  'ماشين لين': 'Machine Learning',
  'ارتيفيشيال انتلجنس': 'Artificial Intelligence',
  'الارتفيشيال انتلجنس': 'Artificial Intelligence',
  'ارتفيشيال انتلجنس': 'Artificial Intelligence',
  'النيورال نتورك': 'Neural Network',
  'الديب ليرنينج': 'Deep Learning',
  'الكلاود كمبيوتينج': 'Cloud Computing',
  'السايبر سكيوريتي': 'Cybersecurity',
  'الايه بي آي': 'API',
  'الفريموورك': 'Framework',
  'الباك اند': 'Backend',
  'الفرونت اند': 'Frontend',
  'اليوزر انترفيس': 'User Interface',
  'اليوزر اكسبيرينس': 'User Experience',
  'البيج داتا': 'Big Data',
  'الداتا ساينس': 'Data Science',
  'الداتا ماينينج': 'Data Mining',
  'الداتا ستركتشر': 'Data Structure',
  'البروجرامينج': 'Programming',
  'الكومبايلر': 'Compiler',
  'الديباجينج': 'Debugging',
  'الفنكشن': 'Function',
  'الفاريبل': 'Variable',
  'الاوبجكت اورينتد': 'Object Oriented',
  'الكلاس': 'Class',
  'الانهيرتنس': 'Inheritance',
  'البوليمورفيزم': 'Polymorphism',
  'الانكابسوليشن': 'Encapsulation',
  'الريكرشن': 'Recursion',
  'الاراي': 'Array',
  'اللينكد ليست': 'Linked List',
  'الستاك': 'Stack',
  'الكيو': 'Queue',
  'البايناري تري': 'Binary Tree',
  'الهاش تيبل': 'Hash Table',
  'السورتينج': 'Sorting',
  'السيرشينج': 'Searching',
  'الكومبلكستي': 'Complexity',
  'الرن تايم': 'Runtime',
  'الاوبريتينج سستم': 'Operating System',
  'الكيرنل': 'Kernel',
  'البروسيس': 'Process',
  'الثريد': 'Thread',
  'السيرفر': 'Server',
  'الكلاينت': 'Client',
  'النتورك': 'Network',
  'البروتوكول': 'Protocol',
  'الانكربشن': 'Encryption',
  'الاوثنتكيشن': 'Authentication',
  // Observed on-device: Deepgram rendered "Authentication" this way in a
  // real course-keyterm-boosted session — boosting raises the odds of
  // hearing the term at all, but doesn't stabilize *which* phonetic
  // spelling comes out, so this is a second real variant, not a guess.
  'اتيتيكيشن': 'Authentication',
  'الاوثورايزيشن': 'Authorization',
  'الفايروول': 'Firewall',
  'الفيرتشوال مشين': 'Virtual Machine',
  'الكونتينر': 'Container',
  'المايكروسيرفسز': 'Microservices',
  'الفيرجن كنترول': 'Version Control',
  'الريبوزيتوري': 'Repository',
  'البرانش': 'Branch',
  'الميرج': 'Merge',
  'الديبلويمنت': 'Deployment',
  'التستينج': 'Testing',
  'الريكوايرمنتس': 'Requirements',
  'الاركيتكتشر': 'Architecture',
  'الديزاين باترن': 'Design Pattern',
  'الانترفيس': 'Interface',
  'الابستراكشن': 'Abstraction',
  'المودل': 'Module',
  'الليبراري': 'Library',
  'الباكج': 'Package',
  'الديبندنسي': 'Dependency',
  'الكويري': 'Query',
  'الانديكس': 'Index',
  'السكيما': 'Schema',
  'الترانزكشن': 'Transaction',
  'الكاش': 'Cache',
  'الليتنسي': 'Latency',
  'الباندويدث': 'Bandwidth',
  'السكيلابيليتي': 'Scalability',
  'اللود بالانسينج': 'Load Balancing',
  'الباك اب': 'Backup',
  'الانترربت': 'Interrupt',
  'الريجستر': 'Register',
  'الميموري': 'Memory',
  'البروسيسور': 'Processor',
  'البت': 'Bit',
  'البايت': 'Byte',
  'البكسل': 'Pixel',
  'الريزوليوشن': 'Resolution',
  'الوايرلس': 'Wireless',
  'الراوتر': 'Router',
  'الجيتواي': 'Gateway',
  'الدومين': 'Domain',
  'التوكن': 'Token',
  'السيشن': 'Session',
  'الكوكي': 'Cookie',
  'الميدلوير': 'Middleware',
  'الاجايل': 'Agile',
  'السبرنت': 'Sprint',
  'الروبوتكس': 'Robotics',
  'التشات بوت': 'Chatbot',
  'البلوكتشين': 'Blockchain',
  'الكريبتوكرنسي': 'Cryptocurrency',
  'الاوجمنتد ريالتي': 'Augmented Reality',
  'الفيرتشوال ريالتي': 'Virtual Reality',
  'الانترنت اوف ثينجز': 'Internet of Things',
  'الكوانتم كمبيوتينج': 'Quantum Computing',
  'الوايرفريم': 'Wireframe',
  'الابلود': 'Upload',
  'الداونلود': 'Download',
  'الابديت': 'Update',
  'الباتش': 'Patch',
  'البج': 'Bug',
  'اللوج': 'Log',
  'الديباج': 'Debug',
  'السينتاكس': 'Syntax',
  'البارامتر': 'Parameter',
  'الارجيومنت': 'Argument',
  'الاوت بوت': 'Output',
  'الانبوت': 'Input',

  // ── Engineering (general) ────────────────────────────────────────
  'السركت': 'Circuit',
  'الثيرموداينمكس': 'Thermodynamics',
  'الميكانكس': 'Mechanics',
  'الستركشورال': 'Structural',
  'الفولتيج': 'Voltage',
  'السينسور': 'Sensor',
  'البروتوتايب': 'Prototype',
  'السميوليشن': 'Simulation',
  'الكاليبريشن': 'Calibration',
  'الكرنت': 'Current',
  'الريزستنس': 'Resistance',
  'الكباستور': 'Capacitor',
  'الريزستور': 'Resistor',
  'الترانزستور': 'Transistor',
  'الدايود': 'Diode',
  'السيمي كوندكتر': 'Semiconductor',
  'الاكتيويتر': 'Actuator',
  'التورك': 'Torque',
  'الفيلوستي': 'Velocity',
  'الاكسلريشن': 'Acceleration',
  'التنسايل': 'Tensile',
  'الكومبريشن': 'Compression',
  'الفتيج': 'Fatigue',
  'الالوي': 'Alloy',
  'الكومبوزيت': 'Composite',
  'الويلدينج': 'Welding',
  'الماشينينج': 'Machining',
  'المانيفاكتشرينج': 'Manufacturing',
  'الفابريكيشن': 'Fabrication',
  'الاسمبلي': 'Assembly',
  'الاوتوميشن': 'Automation',
  'الكنترول سستم': 'Control System',
  'الفيدباك': 'Feedback',
  'السيجنال': 'Signal',
  'الامبليفاير': 'Amplifier',
  'الفلتر': 'Filter',
  'الفريكونسي': 'Frequency',
  'الاوسيليتور': 'Oscillator',
  'التوربين': 'Turbine',
  'الجنريتور': 'Generator',
  'الهايدروليك': 'Hydraulic',
  'النيوماتيك': 'Pneumatic',
  'الشاسيه': 'Chassis',
  'الجير': 'Gear',
  'البيرينج': 'Bearing',
  'الفالف': 'Valve',
  'البمب': 'Pump',
  'البستون': 'Piston',
  'الالاينمنت': 'Alignment',
  'التوليرنس': 'Tolerance',

  // ── Business, management, economics ────────────────────────────────
  'الماركتينج': 'Marketing',
  'الريفينيو': 'Revenue',
  'الستيك هولدر': 'Stakeholder',
  'البدجت': 'Budget',
  'الانفستمنت': 'Investment',
  'المانجمنت': 'Management',
  'الليدرشب': 'Leadership',
  'السبلاي تشين': 'Supply Chain',
  'الكاش فلو': 'Cash Flow',
  'الار او آي': 'ROI',
  'البروفت': 'Profit',
  'الآسيت': 'Asset',
  'الليابيليتي': 'Liability',
  'الايكويتي': 'Equity',
  'الشير هولدر': 'Shareholder',
  'الميرجر': 'Merger',
  'الاكويزيشن': 'Acquisition',
  'الستارت اب': 'Startup',
  'الانتربرينير': 'Entrepreneur',
  'الانوفيشن': 'Innovation',
  'البراندينج': 'Branding',
  'الادفرتايزنج': 'Advertising',
  'البروموشن': 'Promotion',
  'السيجمنتيشن': 'Segmentation',
  'الريتيل': 'Retail',
  'الهول سيل': 'Wholesale',
  'الانفنتوري': 'Inventory',
  'اللوجستكس': 'Logistics',
  'البروكيورمنت': 'Procurement',
  'الاوت سورسينج': 'Outsourcing',
  'النيجوشيشن': 'Negotiation',
  'الكونتراكت': 'Contract',
  'البارتنرشب': 'Partnership',
  'الفرانشايز': 'Franchise',
  'البنشمارك': 'Benchmark',
  'الفوركاست': 'Forecast',
  'البورتفوليو': 'Portfolio',
  'الديفرسفكيشن': 'Diversification',
  'الكومبلاينس': 'Compliance',
  'الاوديت': 'Audit',
  'التاكسيشن': 'Taxation',
  'الانفليشن': 'Inflation',
  'الريسيشن': 'Recession',
  'الجي دي بي': 'GDP',
  'الديفدند': 'Dividend',
  'البوند': 'Bond',
  'الفينتشر كابيتال': 'Venture Capital',
  'الريكروتمنت': 'Recruitment',
  'البروداكتيفيتي': 'Productivity',
  'الافيشنسي': 'Efficiency',
  'التيرن اوفر': 'Turnover',
  'الاوفرهيد': 'Overhead',
  'الليكويديتي': 'Liquidity',
  'الكومودتي': 'Commodity',
  'الانشورنس': 'Insurance',
  'البريميم': 'Premium',
  'السبسيدياري': 'Subsidiary',
  'الكونسوليديشن': 'Consolidation',

  // ── Medical / health (code-switched terms only — see scope note above) ─
  'الدايجنوسس': 'Diagnosis',
  'الكلينكال': 'Clinical',
  'البريسكربشن': 'Prescription',
  'السندروم': 'Syndrome',
  'الكرونك': 'Chronic',
  'الاكيوت': 'Acute',
  'الباثولوجي': 'Pathology',
  'الفيزيولوجي': 'Physiology',
  'الكارديوفاسكيولار': 'Cardiovascular',
  'الريسبيراتوري': 'Respiratory',
  'الراديولوجي': 'Radiology',
  'الفارماكولوجي': 'Pharmacology',
  'الدوسيج': 'Dosage',
  'الانستيزيا': 'Anesthesia',
  'الريهابيليتيشن': 'Rehabilitation',
  'السايكاياتري': 'Psychiatry',
  'الابيديميولوجي': 'Epidemiology',
  'الدي ان ايه': 'DNA',
  'الاوبيستي': 'Obesity',
  'الدايابيتس': 'Diabetes',

  // ── Basic sciences (code-switched terms only — see scope note above) ──
  'الهايبوثيسس': 'Hypothesis',
  'الاكسبريمنت': 'Experiment',
  'اللابراتوري': 'Laboratory',
  'الكاتالست': 'Catalyst',
  'الايكوسستم': 'Ecosystem',
  'الايفوليوشن': 'Evolution',
  'الايكويليبريم': 'Equilibrium',
  'الكونسنتريشن': 'Concentration',
  'الاوكسديشن': 'Oxidation',
  'الايزوتوب': 'Isotope',
  'السبكتروم': 'Spectrum',
  'الكوانتم': 'Quantum',
  'الريلاتيفيتي': 'Relativity',
  'المومنتم': 'Momentum',

  // ── General academic vocabulary (shared across disciplines) ───────
  'الريسيرش': 'Research',
  'الانالسس': 'Analysis',
  'البريزنتيشن': 'Presentation',
  'الاساينمنت': 'Assignment',
  'البروجكت': 'Project',
  'الريفرنس': 'Reference',
  'السيتيشن': 'Citation',
  'الميثودولوجي': 'Methodology',
  'الكونسبت': 'Concept',
  'الثيوري': 'Theory',
  'الموديل': 'Model',
  'الستاتستكس': 'Statistics',
  'السيرفاي': 'Survey',
  'الكويستنير': 'Questionnaire',
  'السامبل': 'Sample',
  'البوبيوليشن': 'Population',
  'الكوريليشن': 'Correlation',
  'الريجريشن': 'Regression',
  'الليتراتشر ريفيو': 'Literature Review',
  'الثيسس': 'Thesis',
  'الديسرتيشن': 'Dissertation',
  'الابستراكت': 'Abstract',
  'الكونكلوجن': 'Conclusion',
  'الانتروداكشن': 'Introduction',
  'الدسكشن': 'Discussion',
  'البير ريفيو': 'Peer Review',
  'البلاجريزم': 'Plagiarism',
  'البيبليوجرافي': 'Bibliography',
  'الكيريكيولم': 'Curriculum',
  'السيلابس': 'Syllabus',
  'السيمينار': 'Seminar',
  'الوركشوب': 'Workshop',
  'السمستر': 'Semester',
  'الفاكلتي': 'Faculty',
  'السكولرشب': 'Scholarship',
  'الجي بي ايه': 'GPA',
  'الكريدت اور': 'Credit Hour',
  'الميجر': 'Major',
  'الماينر': 'Minor',
  'الاليكتف': 'Elective',
  'البريريكوزت': 'Prerequisite',
  'الاكريديتيشن': 'Accreditation',
  'الدبلوما': 'Diploma',
  'الانترنشب': 'Internship',
  'الديدلاين': 'Deadline',
  'الكويز': 'Quiz',
  'الترانسكربت': 'Transcript',
  'الكامبس': 'Campus',
  'الليكتشر': 'Lecture',
  'التيوتوريال': 'Tutorial',
  'الاوت لاين': 'Outline',
  'الدرافت': 'Draft',
  'الريفيجن': 'Revision',
  'الفورمات': 'Format',
  'التمبليت': 'Template',
};

/// Deduplicated English terms from [technicalTermsDictionary] (order of
/// first appearance), for Deepgram's `keyterm` real-time-prompting
/// parameter — see transcription_mobile.dart's Deepgram URL construction.
/// This *boosts Deepgram's own recognition* of these terms as they're
/// spoken, on top of (not instead of) correctTechnicalTerms()'s post-hoc
/// text correction — the two are complementary: keyterm prompting helps
/// Deepgram hear "Machine Learning" correctly in the first place; the
/// corrector still catches phonetic misspellings it produces anyway.
///
/// Deepgram's *documented* limit (developers.deepgram.com/docs/keyterm) is
/// 500 tokens total across all `keyterm` params. That number turned out not
/// to be the real, binding constraint, and neither did two other proxies
/// for it, tried in order as each one failed to generalize:
/// - Raw TERM COUNT: 64 short generic terms (~74 words) connected fine, but
///   64 terms mixing in longer course-style phrases like "Byzantine Fault
///   Tolerance" (~83 words for the same *count* of 64) was rejected — count
///   alone doesn't track it.
/// - WORD COUNT: 88 words of pure short generic terms (69 terms) was
///   REJECTED, while 88 words mixing course-style phrases (61 terms) was
///   ACCEPTED — same word count, opposite outcomes, so word count alone
///   doesn't track it either.
/// - QUERY STRING LENGTH (this one): the one metric that held up across
///   every mix tried. This is the actual physical quantity a URL-length
///   limit would be checking — plausible given the failure is an HTTP 400
///   at the WebSocket handshake, not a semantic "too many boost terms"
///   rejection.
///
/// This number is the result of three full rounds of real binary search
/// against the live Deepgram API with a real key (the two failed proxies
/// above each cost their own binary search before being ruled out; this
/// round: 13 connection attempts, bounds check at 800/3000 chars, binary
/// search narrowing 1900→1350→1075→1213→1282→1248→1265→1257), landing on
/// **an encoded query string of 1243 chars succeeding, 1257 chars failing**,
/// independently reconfirmed 3 consecutive times before being accepted.
/// [kMaxSafeKeytermQueryChars] is set a little under that tested boundary
/// (not at it) specifically because the terms tested here were all
/// plain-English/ASCII; a real course's own keyterms could contain
/// characters (Arabic, accented Latin, punctuation) that percent-encode to
/// more bytes per character than the ASCII terms this was measured with —
/// the margin exists for that, not because the tested boundary itself is
/// treated as unreliable.
///
/// If Deepgram's own limits change in the future, re-run that same
/// mixed-term-shape, character-length binary-search procedure rather than
/// adjusting this number by feel — a term-count-only or word-count-only
/// re-test would silently reintroduce the same gap that broke the first two
/// rounds.
const int kMaxSafeKeytermQueryChars = 1200;

/// The generic, subject-agnostic term list used when there's no
/// course-specific list to combine it with — capped at
/// [kMaxSafeKeytermQueryChars] worth of encoded `&keyterm=...` params. See
/// [buildDeepgramKeytermsWithCoursePriority] for the combined form used by
/// deaf-mode transcription (course keyterms + this list, sharing one
/// overall budget).
final List<String> deepgramKeytermList = _capByQueryChars(
    technicalTermsDictionary.values, kMaxSafeKeytermQueryChars);

/// Caps [terms] by the total encoded length of the `&keyterm=...` params
/// they'd contribute to a Deepgram query string, not by term count or word
/// count (see [kMaxSafeKeytermQueryChars]'s doc comment for why). A term
/// that doesn't fit is skipped rather than stopping the whole pass, so a
/// shorter term later in [terms] can still fit in whatever budget remains —
/// this matters because course-specific terms (checked first by
/// [buildDeepgramKeytermsWithCoursePriority]) can be long phrases that
/// leave an odd amount of remaining budget for the generic dictionary fill.
List<String> _capByQueryChars(Iterable<String> terms, int charBudget,
    {Set<String>? seen}) {
  seen ??= <String>{};
  final result = <String>[];
  var used = 0;
  for (final term in terms) {
    if (!seen.add(term)) continue;
    final paramLength = '&keyterm=${Uri.encodeQueryComponent(term)}'.length;
    if (used + paramLength > charBudget) continue;
    used += paramLength;
    result.add(term);
  }
  return result;
}

/// Combines a course's own approved lecture keyterms (fetched from
/// GET /courses/:courseCode/keyterms — see PlatformClient.getCourseKeyterms)
/// with the generic cross-subject [technicalTermsDictionary] vocabulary,
/// under one shared [kMaxSafeKeytermQueryChars] character budget.
/// Course-specific terms go first — they came from the actual lecture's
/// slides, so they're more valuable signal than the generic list — then
/// whatever budget remains (possibly zero) is filled with generic terms not
/// already covered. If the course's own keyterms alone already exhaust the
/// budget, the generic dictionary is skipped entirely for that session
/// (never silently mixed in over the tested-safe limit). An empty
/// [courseKeyterms] (no course selected, or the course has none yet)
/// degrades gracefully to exactly [deepgramKeytermList].
///
/// The result is also the final safety net before a request ever reaches
/// Deepgram: regardless of how course/generic terms are apportioned, the
/// returned list's total encoded query length can never exceed
/// [kMaxSafeKeytermQueryChars], so callers don't need their own separate
/// truncation step.
List<String> buildDeepgramKeytermsWithCoursePriority(
    List<String> courseKeyterms) {
  if (courseKeyterms.isEmpty) return deepgramKeytermList;
  final seen = <String>{};
  final combined =
      _capByQueryChars(courseKeyterms, kMaxSafeKeytermQueryChars, seen: seen);
  final usedChars = combined.fold<int>(0,
      (sum, t) => sum + '&keyterm=${Uri.encodeQueryComponent(t)}'.length);
  if (usedChars < kMaxSafeKeytermQueryChars) {
    combined.addAll(_capByQueryChars(technicalTermsDictionary.values,
        kMaxSafeKeytermQueryChars - usedChars,
        seen: seen));
  }
  return combined;
}
