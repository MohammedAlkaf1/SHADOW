# شادو (Shadow) — نظرة تقنية شاملة (TECH_OVERVIEW)

**تاريخ إعداد هذا التقرير:** 2026-08-19
**منهجية:** كل رقم أو ادعاء هنا مبني على قراءة فعلية للملفات و/أو تشغيل أوامر فعلية في هذه الجلسة (`git log`, `git status`, `flutter test`, `flutter analyze`, بحث نصي مباشر في الكود). حيث تعذّر التحقق الفعلي، ذلك مذكور صراحة في القسم الأخير.

---

## 1. نظرة عامة (Overview)

- **الاسم (pubspec.yaml → name):** `shadow`
- **الوصف (pubspec.yaml → description):** "Shadow — مرافقك الأكاديمي الذكي"
- **الإصدار الحالي (pubspec.yaml → version):** `1.0.0+1`
- **النوع:** تطبيق Flutter (Android بشكل أساسي؛ iOS موجود في الشجرة لكن غير مستهدَف فعلياً حسب `docs/PROGRESS_REPORT.md`)، **مُصدَّر أصلاً من FlutterFlow** ثم طُوِّر يدوياً فوقه بكثافة (موثّق صراحة في `AGENTS.md` وبنية المجلدات نفسها: `lib/flutter_flow/`, `lib/pages/`, `lib/components/`, `lib/custom_code/actions/`). ملف `README.md` نفسه لا يزال يحمل عنوان "UniAccess" القديم ("FlutterFlow projects are built to run on the Flutter stable release") رغم أن الاسم الفعلي للمشروع أصبح "شادو/Shadow" — أثر تسمية قديم لم يُنظَّف.
- **الغرض:** تطبيق عربي أولاً (RTL-first) موجّه لطلاب الجامعات السعوديين ذوي الإعاقة، بأربعة أوضاع مساعدة مستقلة: الصمم/ضعف السمع (تفريغ حي)، الإعاقة البصرية (وصف صور/قراءة نص)، صعوبات التعلّم (تبسيط PDF)، والإعاقة الحركية (تحكّم صوتي + اتصال سريع). يتصل بمنصة خارجية منفصلة (`D:\Shadow\platform`، ريبو آخر خارج نطاق هذا التقرير) لتسجيل الدخول وتخصيص التكيّف وبوابة تفعيل الأوضاع.

### شجرة المجلدات (مستويين) — root

```
D:\Shadow\app\
├── lib/                    الكود المصدري لتطبيق Flutter (تفصيل أدناه)
├── android/, ios/, web/     مشاريع المنصات الأصلية (Gradle/Xcode/web) التي يولّدها Flutter
├── assets/                  خطوط، صور، فيديوهات، صوتيات، Rive، PDFs تجريبية، jsons، ترجمات
├── test/                    7 ملفات اختبار Dart (تفصيل في القسم 7)
├── docs/                    توثيق داخلي: تدقيق، تقدّم، حالة نهائية، خارطة طريق، خطة تكيّف، اختبار إتاحة (تفصيل في القسم 9)
├── tool/                    أدوات مساعدة دخل مطوّر فقط (مثل `tool/asr_spike` لقياس دقة Deepgram، `tool/icon_gen`)
├── firebase/                قواعد Firestore/Storage وCloud Functions (Firebase غير مُستخدَم فعلياً من كود التطبيق حالياً — انظر القسم 3)
├── .claude/, .idea/, .vscode/  إعدادات أدوات محرر/مساعد
├── env.json / env.example.json  مفاتيح البيئة (env.json غير متتبَّع بـ git)
├── pubspec.yaml / pubspec.lock  تعريف الحزم
├── analysis_options.yaml   إعداد المحلّل الساكن (lints)
├── AGENTS.md               "مصدر الحقيقة" لطريقة العمل في هذا الريبو — يمنع صراحة الهجرة لـRiverpod/بنية مختلفة
├── README.md                تعليمات إعداد وتشغيل (لا يزال يحمل اسم "UniAccess" في العنوان)
├── build/, .dart_tool/       نواتج بناء (غير متتبَّعة عادة)
└── scratch_shots/, flutter_01.png, flutter_01.log  ملفات تشخيص/لقطات متروكة من جلسات سابقة
```

### شجرة `lib/` (مستويين)

```
lib/
├── main.dart                نقطة الدخول: تهيئة Firebase، FFAppState، easy_localization، MultiProvider، MaterialApp.router
├── app_state.dart            FFAppState (حالة FlutterFlow العامة، Provider/ChangeNotifier)
├── index.dart                يُصدّر (export) كل صفحات lib/pages للاستخدام في نظام التوجيه
├── theme.dart                مصدر وحيد للألوان (فاتح/داكن)، المسافات، الخطوط (Tajawal)، رسائل مُلطَّفة، ديكورات مشتركة
├── a11y.dart                 أدوات إتاحة مشتركة: a11yButton, a11yLive, appBackIcon
├── flutter_flow/              كود FlutterFlow المولَّد (نظرياً لا يُعدَّل يدوياً حسب AGENTS.md): theme قديم، أدوات، نظام التوجيه (nav/)
│   └── nav/                  GoRouter + FFRoute + منطق الانتقالات (page_transition)
├── pages/                     كل شاشات التطبيق (تفصيل كامل في القسم 6)
├── components/                عناصر واجهة قابلة لإعادة الاستخدام: أزرار، بطاقات إعاقة، شارات حالة، سلايدر...
├── services/                  منطق أعمال بلا واجهة: عميل الذكاء الاصطناعي، عميل المنصة، تخزين محلي، تفريغ Deepgram، قاموس مصطلحات، سجل مرشد
├── student/                   نموذج ملف الطالب (StudentProfile) ومزوّده (Provider)
├── style/                     عناصر واجهة مرتبطة بمنطق فئة الطالب (category_widgets.dart)
├── data/                      القاموس التقني الثابت (technical_terms_dictionary.dart)
├── backend/                   بقايا FlutterFlow: تهيئة Firebase + مخططات Firestore (غير مستخدَمة فعلياً من التطبيق)
└── custom_code/                إجراءات يدوية مكتوبة فوق تصدير FlutterFlow: Deepgram streaming، استدعاءات AI، TTS، أوامر صوتية
```

---

## 2. التقنيات والاعتماديات (Tech & Dependencies)

تمت قراءة `pubspec.yaml` بالكامل (194 سطراً).

**قيود SDK (`environment:`):** `sdk: ">=3.0.0 <4.0.0"` — لا يوجد قيد صريح على إصدار Flutter نفسه في هذا الملف (فقط Dart SDK).

### التبعيات المباشرة (`dependencies:`) — مصنّفة

**SDK الأساسي (Flutter نفسه):**
- `flutter` (sdk), `flutter_localizations` (sdk), `flutter_web_plugins` (sdk)

**الشبكة (HTTP):**
- `http: ^1.0.0` (مع `dependency_overrides: http: 1.4.0`)

**Firebase (مُهيَّأ لكن غير مستخدَم فعلياً من منطق التطبيق — انظر القسم 3):**
- `cloud_firestore: 5.6.9`, `cloud_firestore_platform_interface: 6.6.9`, `cloud_firestore_web: 4.4.9`
- `firebase_core: 3.14.0`, `firebase_core_platform_interface: 5.4.0`, `firebase_core_web: 2.23.0`
- `firebase_performance: 0.10.1+7`, `firebase_performance_platform_interface: 0.1.5+7`, `firebase_performance_web: 0.1.7+13`

**التخزين المحلي / تفضيلات:**
- `shared_preferences: 2.5.3` + منصّاته (`_android 2.4.10`, `_foundation 2.5.4`, `_linux 2.4.1`, `_platform_interface 2.4.1`, `_web 2.4.3`, `_windows 2.4.1`)
- `sqflite: 2.3.3+1`, `sqflite_common: 2.5.4+3`
- `flutter_secure_storage: ^10.3.1`
- `path_provider: 2.1.4` + منصّاته (`_android 2.2.10`, `_foundation 2.4.0`, `_linux 2.2.1`, `_platform_interface 2.1.2`, `_windows 2.3.0`)

**الصوت/الميكروفون:**
- `record:` (بدون قيد إصدار صريح في pubspec — القيمة فارغة بعد `:`)

**الوسائط/الملفات:**
- `image_picker: ^1.0.0`
- `file_picker: ^8.0.0`
- `syncfusion_flutter_pdf: ^33.2.8`
- `flutter_tts: ^3.8.5`
- `cached_network_image: 3.4.1` + `cached_network_image_platform_interface: 4.1.1` + `cached_network_image_web: 1.3.1`
- `flutter_cache_manager: 3.4.1`

**الخرائط (موجودة في الحزمة لكن لم يُتحقَّق من استخدامها الفعلي في هذه الجلسة):**
- `google_maps: 8.1.1`, `google_maps_flutter: 2.12.2` + منصّاته (`_android 2.16.1`, `_ios 2.15.2`, `_platform_interface 2.12.1`, `_web 0.5.12`)

**التوجيه (Routing):**
- `go_router: 12.1.3`
- `page_transition: 2.1.0`

**إدارة الحالة:**
- `provider: 6.1.5`

**التدويل/الترجمة:**
- `easy_localization: ^3.0.7`
- `intl: 0.20.2`
- `timeago: 3.7.1`

**واجهة المستخدم / الخطوط / الرسوم:**
- `google_fonts: 6.3.3`
- `font_awesome_flutter: 10.7.0`
- `auto_size_text: 3.0.0`
- `flutter_animate: 4.5.0`
- `percent_indicator: 4.2.2`
- `from_css_color: 2.0.0`
- `cupertino_icons: ^1.0.0`

**أذونات النظام:**
- `permission_handler:` (بدون قيد إصدار صريح)

**شبكات/اتصالات فرعية:**
- `web_socket_channel:` (بدون قيد إصدار صريح — يُستخدم لتفريغ Deepgram الحي)
- `url_launcher: 6.3.1` + منصّاته (`_android 6.3.16`, `_ios 6.3.3`, `_linux 3.2.1`, `_macos 3.2.2`, `_platform_interface 2.3.2`, `_web 2.4.1`, `_windows 3.1.4`)

**أدوات/بنية عامة:**
- `collection: 1.19.1`
- `json_path: 0.7.2`
- `stream_transform: 2.1.0`
- `plugin_platform_interface: 2.1.8`
- `flutter_plugin_android_lifecycle: 2.0.28`

### `dependency_overrides:`
- `http: 1.4.0`
- `uuid: ^4.0.0`
- `sqlite3: ">=2.4.0 <3.0.0"` — تعليق الكود يوضّح: هذا **للاختبارات فقط** (`sqflite_common_ffi` غير متوافق مع `sqlite3` 3.x على منصة اختبار سطح المكتب)، ولا يؤثر على التطبيق الفعلي الذي يستخدم إضافة `sqflite` على Android.

### `dev_dependencies:`
- `flutter_lints: 4.0.0`
- `lints: 4.0.0`
- `flutter_test:` (sdk)
- `sqflite_common_ffi: ^2.3.3` — تعليق الكود: للاختبار فقط، يشغّل sqflite على آلة سطح المكتب الافتراضية بلا جهاز
- `flutter_launcher_icons: ^0.14.1` — لتوليد أيقونة التطبيق من `assets/icon/app_icon.png`
- `flutter_secure_storage_platform_interface: ^2.0.3`

**ملاحظة:** `AGENTS.md` يمنع صراحة تشغيل `flutter pub upgrade` أو رفع إصدارات الحزم دون إذن صريح من صاحب المشروع ("المجموعة مثبَّتة ومُختبَرة").

---

## 3. المعمارية (Architecture)

### الواجهة الأمامية (Frontend)
- **مزيج FlutterFlow + كود يدوي:** بنية المجلدات كاملة (`lib/flutter_flow/`, `lib/pages/*_widget.dart` + `*_model.dart`, `lib/components/`, `lib/backend/`) هي بنية تصدير FlutterFlow القياسية. لكن شاشات كاملة أُضيفت يدوياً بلا نمط FlutterFlow (لا يوجد لها `_model.dart`): `lib/pages/login/login_widget.dart`, `lib/pages/consent/consent_screen.dart`, `lib/pages/settings/settings_screen.dart` (توثَّق ذلك صراحة في تعليق أعلى `login_widget.dart`: "Not a FlutterFlow-generated page").
- **إدارة الحالة:** `provider` (الحزمة `provider: 6.1.5`) + نمط FlutterFlow الخاص `FFAppState` (`lib/app_state.dart`, singleton `ChangeNotifier`). تم التحقق فعلياً من `lib/main.dart` (يسجّل `ChangeNotifierProvider(create: (context) => appState)` و`ChangeNotifierProvider(create: (context) => StudentProfileProvider())` عبر `MultiProvider`). لا وجود لـ Riverpod أو Bloc في `pubspec.yaml` ولا في الكود الذي قُرئ. `StudentProfileProvider` (`lib/student/student_profile_provider.dart`) يتبع نفس نمط الـ singleton الذي يتبعه `FFAppState`.
- **الثيمنغ:** `lib/theme.dart` هو المصدر الوحيد المُلزم (تعليق أعلى الملف: "the single source of truth for colours, spacing, and Arabic typography"). يحتوي `AppColors` (فاتح/داكن، كـ getters تتبع `Brightness` الحالي — وليست `static const`، حسب توثيق صريح في الكود لأن ذلك يسمح بتبديل السطوع وقت التشغيل)، `EchoColors` (تصميم الشاشة الرئيسية الجديد "primary card"/"echo layer")، `AppSpacing`, `AppText` (خط Tajawal عبر `google_fonts` مع إصلاح `TextLeadingDistribution.even` لمشكلة قصّ الحروف العربية الطويلة)، `AppMessages` (تلطيف رسائل الخطأ حسب فئة الطالب)، `AppDecor`.
- **نظام التوجيه:** `go_router: 12.1.3` مُغلَّف داخل بنية FlutterFlow الخاصة (`lib/flutter_flow/nav/nav.dart` — `createRouter()`, `FFRoute`, `FFParameters`). المسارات المسجَّلة فعلياً (قراءة مباشرة للملف): `/` (Splash)، `/login`، `/deafModeTranscription`، `/learningSupportMode`، `/physicalAssistanceMode`، `/visualAssistanceMode`، `/welcomeSelection`، `/settings`. لا وجود لمسار `dev_tools` في نسخة `nav.dart` الحالية في شجرة العمل (حُذف — انظر القسم 9، هذا تغيير غير مُثبَّت بـ commit بعد).

### "الخلفية" (Backend) — منصة خارجية
- التطبيق **عميل** لمنصة خارجية منفصلة (`D:\Shadow\platform`، ريبو آخر لم يُدقَّق هنا). ملف الاتصال: `lib/services/platform_client.dart` (381 سطراً، قُرئ بالكامل).
- **متغيّر BASE URL:** `PLATFORM_BASE_URL` (يُقرأ عبر `String.fromEnvironment('PLATFORM_BASE_URL', defaultValue: 'http://localhost:3000/api')`).
- **آلية المصادقة:** Bearer JWT من نمط access/refresh token: `login()` يرسل `POST /auth/login` (email/password) ويحصل على `accessToken` (يُحفَظ في الذاكرة فقط، حقل `static String? _accessToken`، لا يُكتَب على القرص أبداً) و`refreshToken` (يُخزَّن في `flutter_secure_storage` **فقط إن اختار الطالب "تذكرني"**). الطلبات المصادَق عليها تُرسِل ترويسة `Authorization: Bearer $token`. عند 401 يُعاد المحاولة مرة واحدة بعد `POST /auth/refresh`. لا يوجد منطق "session/cookie" — الآلية بالكامل JWT.
- **الأحداث:** `queueUsageEvent`/`flushQueuedEvents` — أحداث استخدام (metadata فقط: `mode_opened`, `tool_used`, `provider_error`، لا صوت ولا صورة ولا نص محادثة) تُجمَّع محلياً وتُرسَل دفعة كل 60 ثانية (`Timer.periodic`) أو عند إغلاق شاشة وضع، أيهما أسبق — عبر `POST /events`.
- **تصميم offline-first:** كل قراءة (`getStudentProfile`, `getSupportPlan`) تحاول شبكة أولاً، وتسقط تلقائياً على نسخة محفوظة محلياً (`AppPrefs.getCachedProfileJson`) عند الفشل — لا يوجد مسار يحجب وضعاً بسبب انقطاع الشبكة.

### قاعدة البيانات المحلية
- **لا توجد قاعدة بيانات سحابية/بعيدة يستخدمها التطبيق فعلياً.** التطبيق يستخدم **sqflite محلياً على الجهاز فقط** لغرض واحد: حفظ نصوص التفريغ الحيّ (`lib/services/transcript_store.dart`، قاعدة `shadow_transcripts.db`، جدول `transcripts`) — تعليق الملف صريح: "transcripts never leave the device. There is no sync, no upload, no backend." الحفظ يشمل انتهاء صلاحية تلقائي (افتراضياً 30 يوماً، قابل للتعديل عبر `AppPrefs.getRetentionDays`/`setRetentionDays`) وحذفاً فردياً/كاملاً (مُتحقَّق منه باختبارات `test/transcript_store_test.dart`).
- **Firestore/Firebase موجود في الشجرة لكن غير مستخدَم من منطق التطبيق فعلياً:** `lib/backend/firebase/firebase_config.dart` و`lib/backend/schema/*` (كلاسات `transcriptions_record.dart`, `documents_record.dart`, `user_profile_record.dart`) موجودة، ويُستدعى `initFirebase()` في `main.dart`، لكن قواعد `firebase/firestore.rules` مقفلة صراحة (`allow read, write: if false`) مع تعليق داخل الملف نفسه يوثّق أن هذا القرار اتُّخذ بعد التحقق أن "لا كود تطبيق يقرأ أو يكتب Firestore… مجرد بقايا FlutterFlow scaffolding غير مستخدَمة".
- **SharedPreferences مقابل flutter_secure_storage — من ماذا يُخزَّن أين (`lib/services/app_prefs.dart`, قُرئ بالكامل):**
  - **SharedPreferences (غير مشفّرة):** رقم الاتصال السريع (`quick_contact_number`)، مدة الاحتفاظ بالتفريغات (`transcript_retention_days`)، موافقة الذكاء الاصطناعي (`ai_consent`)، نسخة مخبَّأة من ملف الطالب من المنصة (`platform_cached_profile_json`)، طابور أحداث الاستخدام غير المُرسَلة (`platform_queued_events_json`)، لغة التطبيق (`app_language`).
  - **flutter_secure_storage (Android Keystore/EncryptedSharedPreferences، iOS Keychain):** refresh token للمنصة ("تذكرني"، `platform_refresh_token`) — تعليق الكود يوضّح صراحة: "deliberately not SharedPreferences, since that's plain-text and this is long-lived (30-day) authentication data"؛ وبريد/كلمة مرور الطالب الفعليين لتعبئة نموذج الدخول تلقائياً عند تفعيل "تذكرني" (`saved_email`, `saved_password`, `remember_me`). كلمة المرور **لا تُخزَّن أبداً** إن لم يُفعَّل "تذكرني".
  - **access token للمنصة:** لا يُخزَّن على القرص إطلاقاً بأي شكل — في الذاكرة فقط طوال عمر العملية.

### المصادقة (Auth) وتسجيل الدخول
- شاشة الدخول (`lib/pages/login/login_widget.dart`) نموذج بريد/كلمة مرور بسيط (StatefulWidget، ليس صفحة FlutterFlow). عند الإرسال يستدعي `PlatformClient.login(email, password, rememberMe:)`.
- **"تذكرني" (checkbox، مفعَّل افتراضياً `_rememberMe = true`):**
  - إن كان مفعَّلاً: يُخزَّن refresh token في `flutter_secure_storage`، ويُخزَّن البريد/كلمة المرور الخام أيضاً في `flutter_secure_storage` (وليس SharedPreferences) لتعبئة النموذج تلقائياً لاحقاً.
  - إن كان معطَّلاً: يُمسَح أي refresh token محفوظ سابقاً صراحة (خيار "لا تتذكرني" ينظّف الحالة القديمة أيضاً).
  - عند بدء التطبيق، شاشة `splash_screen_widget.dart` تستدعي `PlatformClient.tryRestoreSession()` والتي تحاول تبادل الـ refresh token المحفوظ (إن وُجد) بجلسة جديدة عبر `/auth/refresh` **قبل** عرض شاشة الدخول، فإن نجحت يذهب المستخدم مباشرة لشاشة اختيار الوضع.
  - **ملاحظة موثَّقة في `docs/FINAL_STATUS_APP.md`:** رغم أن منطق "تذكرني" مكتمل بالكود ومُغطّى بـ 5 اختبارات وحدة تمر جميعها (`test/remember_me_test.dart`)، **أبلغ المستخدم أن الميزة لا تعمل فعلياً على جهاز حقيقي** ولم يُعثَر على السبب الجذري حتى تاريخ ذلك التقرير (2026-08-13) — أُضيف تسجيل تشخيصي (`debugPrint`) في كل نقطة قرار لتتبّع السبب لاحقاً. هذه نقطة **مفتوحة، غير مغلقة**.

### التخزين المحلي/الملفات — ملخص شامل
- بيانات غير حسّاسة (تفضيلات، لغة، طابور أحداث): SharedPreferences، غير مشفّرة.
- بيانات اعتماد/جلسة طويلة الأمد: `flutter_secure_storage` (مشفّرة عبر Android Keystore/EncryptedSharedPreferences أو iOS Keychain).
- نصوص التفريغ الحي المحفوظة: sqflite محلي، بلا تشفير إضافي موثَّق (طبقة نظام الملفات القياسية فقط)، مع انتهاء صلاحية تلقائي وحذف يدوي.
- لا رفع/مزامنة سحابية لأي من هذه البيانات إلى خوادم شادو نفسها؛ الاستثناء الوحيد هو ما يُرسَل صراحة لخدمات الذكاء الاصطناعي الخارجية (صوت/صورة/نص PDF يختاره الطالب) والأحداث التعريفية المُرسَلة للمنصة.

---

## 4. الخدمات الخارجية (Third-party services)

تم التحقق من كل خدمة عبر قراءة مباشرة لملفات الخدمة، وليس افتراضاً.

### 1. Deepgram — تفريغ صوتي حي (Speech-to-Text)
- **الغرض:** تفريغ صوت المحاضرة الحي إلى نص (وضع الصمم)، وأوامر صوتية (وضع الحركية).
- **ملفات التكامل:** `lib/custom_code/actions/transcription_mobile.dart` (الأساسي، تدفّق WebSocket)، `lib/custom_code/actions/transcription_web.dart` (نسخة الويب، **مُستثناة من `flutter analyze`** حسب `analysis_options.yaml`)، `lib/custom_code/actions/transcription_stub.dart`، `lib/custom_code/actions/listen_for_voice_command.dart`، `lib/custom_code/actions/start_realtime_transcription.dart`، `lib/services/deepgram_parser.dart` (تحليل رسائل JSON الواردة).
- **الإعداد المؤكَّد من الكود:** الاتصال بـ `wss://api.deepgram.com/v1/listen`، الموديل `nova-3` (تعليق بالكود يوثّق أن `nova-2` كان يرفض `language=ar` بخطأ 400)، معامِلات `language=$deepgramLanguage&model=nova-3&smart_format=true&interim_results=true`، والمصادقة عبر ترويسة `Authorization: Token $_apiKey` (وليس عبر رابط الاستعلام — تعليق بالكود يوثّق أن هذا إصلاح لاحق لأن التوكن في الرابط "أكثر عرضة للتسريب عبر السجلات/الكاش").
- **متغيّر البيئة:** `DEEPGRAM_API_KEY` (اسم فقط، القيمة الفعلية لم تُقرأ/تُطبَع في هذه الجلسة).

### 2. Google Gemini — رؤية حاسوبية وتبسيط مستندات (LLM)
- **الغرض:** وصف الصور/قراءة النص المرئي (وضع الإعاقة البصرية)، وتلخيص/تبسيط ملفات PDF وتوليد أسئلة مراجعة (وضع صعوبات التعلّم)، وتلخيصات دورية صامتة داخل محرك التكيّف.
- **ملف التكامل (نقطة التبديل الوحيدة حسب تعليق الملف):** `lib/services/ai_client.dart` (قُرئ بالكامل).
- **الإعداد المؤكَّد من الكود:** `kAiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta'`، `kAiModel = 'gemini-2.5-flash'`، المصادقة عبر ترويسة `x-goog-api-key`، endpoint: `{base}/models/{model}:generateContent`. `thinkingConfig.thinkingBudget` مضبوط على 0 عمداً (تعليق: لتفادي رد فارغ بسبب استهلاك ميزانية التفكير).
- **متغيّر البيئة:** `GEMINI_API_KEY` (اسم فقط).
- **الملاحظة الأهم (تناقض توثيقي مؤكَّد):** `AGENTS.md` (آخر تحديث موثَّق 2026-07-24) لا يزال يذكر **Kimi (Moonshot)** كمزوّد الذكاء الاصطناعي الحالي، و`README.md` لا يزال يذكر `OPENAI_API_KEY` كمثال في التوثيق. لكن الكود الفعلي (`ai_client.dart`) ومحتوى `env.example.json` يستخدمان **Gemini حصراً**. `docs/FINAL_STATUS_APP.md` (2026-08-13) يوثّق صراحة أن المزوّد تحوّل: OpenAI GPT-4o ← Kimi ← Gemini (التحويل الأخير كان بسبب خطأ 429/quota من Kimi)، وأن `AGENTS.md` نفسه "متأخر عن الكود الفعلي" في هذه النقطة. أسماء ملفات الإجراءات (`analyze_image_with_gpt4o.dart`, `process_document_with_gpt4o.dart`) لا تزال تحمل اسم "gpt4o" رغم أنها تستدعي Gemini فعلياً الآن — أثر تسمية قديم لم يُصحَّح.

### 3. Firebase (Core / Firestore / Performance)
- **الحالة:** مُهيَّأ في `main.dart` (`initFirebase()`) لكن **غير مستخدَم فعلياً** لتخزين أو قراءة أي بيانات تطبيق (مؤكَّد بقراءة `firebase/firestore.rules` — مقفل بالكامل `allow read, write: if false` مع تعليق يوثّق أن هذا تحقَّق منه صراحة). يُصنَّف عملياً كبقايا (dead weight) من التصدير الأصلي وليس خدمة نشطة.
- **الغرض النظري (غير مفعَّل):** تخزين سحابي (Firestore)، قياس أداء (`firebase_performance`).

### 4. منصة شادو الخارجية (Shadow Platform)
مذكورة في القسم 3 أعلاه — ليست "خدمة طرف ثالث" بالمعنى التجاري بل الخلفية الخاصة بالمشروع (ريبو منفصل)، لذا لم تُكرَّر هنا كخدمة AI/طرف ثالث تجاري.

**لم يُعثَر على أي خدمة أخرى** (لا OpenAI مباشرة، لا Vertex AI، لا خدمات تحليلات طرف ثالث أخرى) في الملفات التي قُرئت هذه الجلسة.

---

## 5. متغيّرات البيئة (Environment variables)

المصدر: `env.example.json` (القالب المتتبَّع بـ git) و`env.json` (الفعلي، **غير متتبَّع** — تم قراءة أسماء المفاتيح فيه فقط، لا القيم) — كلاهما يُقرأ عبر `String.fromEnvironment` في وقت البناء عبر `--dart-define-from-file=env.json` (مؤكَّد من `README.md` وكود `ai_client.dart`/`platform_client.dart`).

| المتغيّر | الوصف (من السياق/التعليقات في الكود) |
|---|---|
| `DEEPGRAM_API_KEY` | مفتاح خدمة Deepgram للتفريغ الصوتي الحي وأوامر الصوت — يُقرأ في `lib/custom_code/actions/transcription_mobile.dart` وملفات الإجراءات الصوتية الأخرى. تركه فارغاً يعني ظهور رسالة "المفتاح مفقود" بدل عمل هذه الميزات. |
| `GEMINI_API_KEY` | مفتاح Google Gemini للرؤية الحاسوبية وتبسيط المستندات — يُقرأ في `lib/services/ai_client.dart` (`String.fromEnvironment('GEMINI_API_KEY')`). فارغ = رسالة خطأ عربية واضحة بدل تعطّل صامت. |
| `PLATFORM_BASE_URL` | عنوان الأساس (base URL) لواجهة برمجة منصة شادو الخارجية — يُقرأ في `lib/services/platform_client.dart` بقيمة افتراضية `http://localhost:3000/api` إن لم يُمرَّر. |

**ملاحظة:** `README.md` يذكر أيضاً `OPENAI_API_KEY` كمثال ضمن نص إرشادي، لكن هذا المتغيّر **غير موجود فعلياً** في `env.example.json` ولا `env.json` ولا يُقرأ في أي كود تم فحصه — توثيق قديم متبقٍّ من مرحلة سابقة (عندما كان المزوّد OpenAI فعلاً، قبل التحويل لـ Gemini).

لا قيمة فعلية لأي متغيّر ذُكرت في هذا التقرير أو عُرضت في أي مخرجات أوامر.

---

## 6. الشاشات (Screens)

الجدول يغطي كل ملف تحت `lib/pages/` (تم التحقّق من مصادر التنقّل بالبحث المباشر عن `context.go`/`context.pushNamed`/`Navigator.push`، وليس تخميناً).

| الملف | الغرض | من أي شاشة يُوصل إليها |
|---|---|---|
| `lib/pages/splash_screen/splash_screen_widget.dart` (`/`) | شاشة بداية (2 ثانية على الأقل)، تحاول استرجاع جلسة منصة سابقة (`tryRestoreSession`) وتقرر التوجيه التالي | نقطة الدخول الأولى للتطبيق (`initialLocation` في GoRouter) |
| `lib/pages/login/login_widget.dart` (`/login`) | تسجيل الدخول بحساب منصة شادو (بريد/كلمة مرور + "تذكرني") | من splash screen إذا فشل استرجاع الجلسة؛ ومن `settings_screen.dart` بعد تسجيل الخروج (`context.go(LoginWidget.routePath)`) |
| `lib/pages/welcome_selection/welcome_selection_widget.dart` (`/welcomeSelection`) | الشاشة الرئيسية — اختيار أحد الأوضاع الأربعة (تُخفي أي وضع غير مفعَّل على SupportPlan الطالب عبر `_isModeEnabled`)، بطاقة "آخر جلسة"، دخول للإعدادات | من splash screen إذا نجح استرجاع الجلسة؛ ومن `login_widget.dart` بعد نجاح تسجيل الدخول (`context.go`) |
| `lib/pages/deaf_mode_transcription/deaf_mode_transcription_widget.dart` (`/deafModeTranscription`) | وضع الصمم: تفريغ صوتي حي عبر Deepgram، تصحيح مصطلحات تقنية، تلخيص دوري، TTS، حفظ محلي | من `welcome_selection_widget.dart` (`context.pushNamed`)؛ ومن `physical_assistance_mode_widget.dart` عبر أمر صوتي "الصمم/deaf/hearing" (`context.pushNamed('DeafModeTranscription')`) |
| `lib/pages/deaf_mode_transcription/saved_transcripts_page.dart` | عرض/حذف النصوص المحفوظة محلياً (sqflite) | من `deaf_mode_transcription_widget.dart` فقط (`Navigator.push(MaterialPageRoute(...SavedTranscriptsPage()))`) |
| `lib/pages/visual_assistance_mode/visual_assistance_mode_widget.dart` (`/visualAssistanceMode`) | وضع الإعاقة البصرية: التقاط صورة، تحليلها عبر Gemini (وصف/قراءة نص)، TTS | من `welcome_selection_widget.dart` (`context.pushNamed`)؛ ومن `physical_assistance_mode_widget.dart` عبر أمر صوتي "بصري/visual/vision" |
| `lib/pages/learning_support_mode/learning_support_mode_widget.dart` (`/learningSupportMode`) | وضع صعوبات التعلّم: رفع PDF، معالجته عبر Gemini (تلخيص/تبسيط/أسئلة)، TTS | من `welcome_selection_widget.dart` (`context.pushNamed`)؛ ومن `physical_assistance_mode_widget.dart` عبر أمر صوتي "تعلم/learning/study" |
| `lib/pages/physical_assistance_mode/physical_assistance_mode_widget.dart` (`/physicalAssistanceMode`) | وضع الإعاقة الحركية: تحكّم صوتي (تنقّل بين الأوضاع)، زر "اتصال سريع" حقيقي (`tel:` عبر `url_launcher`) | من `welcome_selection_widget.dart` (`context.pushNamed`) |
| `lib/pages/settings/settings_screen.dart` (`/settings`) | إعدادات التطبيق: تبديل اللغة (عربي/إنجليزي)، الوضع الليلي، تسجيل الخروج | من `welcome_selection_widget.dart` (`context.pushNamed(SettingsScreen.routeName)`) |
| `lib/pages/consent/consent_screen.dart` | شاشة موافقة أولى على إرسال بيانات لخدمات ذكاء اصطناعي خارجية (Deepgram/Gemini) — `fullscreenDialog` | تُستدعى برمجياً (`ensureAiConsent`/`showAiConsent`) من أول استخدام لأي ميزة ذكاء اصطناعي، ومن `welcome_selection_widget.dart` عند أول تشغيل للتطبيق (`postFrameCallback`)؛ ليست ضمن مسارات GoRouter (`Navigator.push` مباشر، ليست `FFRoute`) |

**ملاحظة:** `lib/pages/dev_tools/dev_tools_page.dart` (شاشة أدوات مطوّر محمية بـ `kDebugMode`، مذكورة بكثافة في `docs/`) **محذوفة في شجرة العمل الحالية غير المُثبَّتة (`git status` يُظهرها كـ `D` — deleted، لم يُعمَل لها commit بعد)** — لذلك لا تظهر في القائمة أعلاه رغم توثيقها التاريخي في `docs/PROGRESS_REPORT.md`/`FINAL_STATUS_APP.md`.

---

## 7. الاختبارات والجودة (Tests & quality)

### ملفات الاختبار (7 ملفات، 665 سطراً إجمالاً — عدّ فعلي)

| الملف | الأسطر | يغطي |
|---|---|---|
| `test/deepgram_parser_test.dart` | 97 | تحليل رسائل Deepgram (interim/final/error)، تجميع النص عبر `TranscriptAccumulator` |
| `test/transcript_store_test.dart` | 98 | حفظ/جلب/حذف التفريغات محلياً، انتهاء الصلاحية (30 يوماً) |
| `test/app_prefs_test.dart` | 56 | رقم الاتصال السريع، مدة الاحتفاظ، موافقة الذكاء الاصطناعي |
| `test/consent_gate_test.dart` | 95 | حارس الموافقة `ensureAiConsent` |
| `test/technical_terms_corrector_test.dart` | 104 | مطابقة/تصحيح القاموس التقني (بما فيها حالات "ال" التعريف) |
| `test/remember_me_test.dart` | 172 | محاكاة كاملة لتدفّق "تذكرني" (login/refresh/restore) بدون جهاز حقيقي |
| `test/adaptive_prompts_language_test.dart` | 43 | اختيار برومبت Gemini حسب لغة التطبيق (عربي/إنجليزي) |

### نتيجة تشغيل `flutter test` فعلياً في هذه الجلسة
```
56/56 ناجحة، 0 فاشلة — "All tests passed!"
```
(شمل التشغيل الافتراضي كل الملفات السبعة، بما فيها `deepgram_parser_test.dart` — وهو الملف الذي وثّق `docs/FINAL_STATUS_APP.md` سابقاً أنه أحياناً لا يُشغَّل ضمن الأمر الافتراضي بسبب غير معروف؛ في هذا التشغيل ظهر ضمن النتيجة الإجمالية 56/56، وهو نفس الرقم الذي وثّقه ذلك التقرير في قياسه الثاني).

### `analysis_options.yaml`
يفعّل `package:flutter_lints/flutter.yaml` القياسية فقط، بدون قواعد صارمة إضافية (لا `strict-casts`/`strict-raw-types`). استثناء واحد صريح: `lib/custom_code/actions/transcription_web.dart` مُستبعَد من التحليل بالكامل. تعطيل واحد صريح: `unnecessary_string_escapes: false`.

### نتيجة تشغيل `flutter analyze lib/` فعلياً في هذه الجلسة
```
0 أخطاء (errors)
190 تحذيراً (warnings)
195 معلومة (info)
= 385 مشكلة إجمالاً — لا شيء يمنع البناء
```
معظمها استيرادات غير مستخدَمة (`unused_import`)، استخدام API مهجور من Flutter نفسه (`deprecated_member_use` — مثل `groupValue`/`onChanged` على `Radio` و`encryptedSharedPreferences`)، وتفضيلات أسلوبية (`prefer_const_constructors`). لا توجد أخطاء حرجة.

### `flutter build apk --debug --dart-define-from-file=env.json`
**نُفِّذ فعلياً حتى النهاية في جلسة تحليل موازية لهذا التقرير (نفس الريبو، نفس الوقت تقريباً).** النتيجة الفعلية: **فشل البناء** — `BUILD FAILED in 1m 6s`, exit code 1 — لكن **ليس بسبب خطأ في كود Dart/Flutter**. مخرجات Gradle الحرفية:
```
Execution failed for task ':app:cleanMergeDebugAssets'.
> java.io.IOException: Unable to delete directory
  'D:\Shadow\app\build\app\intermediates\assets\debug\mergeDebugAssets'
  Failed to delete some children. This might happen because a process
  has files open or has its working directory set in the target directory.
  - ...\mergeDebugAssets\flutter_assets\kernel_blob.bin
  - ...\mergeDebugAssets\flutter_assets
```
هذا عطل بيئة Windows نمطي (قفل ملف من عملية أخرى ظلّت فاتحة على مجلد `build/`)، وليس عطلاً في كود التطبيق أو تبعياته — لم يُعَد تشغيل البناء بعد هذا الفشل للتأكد من أنه عابر، فهذه هي المخرجات الفعلية الوحيدة المرصودة ولا يصح افتراض ما بعدها. `flutter doctor` (نُفِّذ فعلياً) يُظهر تحذيراً غير حاجز إضافياً: مسار Android SDK يحوي مسافة (`C:\Users\Mohammed Alkaf\AppData\Local\Android\sdk`)، غير مستحسَن لأدوات NDK لكنه لم يمنع بدء البناء. ملف `android/app/google-services.json` **موجود محلياً** فعلياً (رغم كونه مستثنى من git). الدليل الفعلي البديل الأقوى على سلامة كود Dart نفسه يبقى `flutter analyze` (0 أخطاء) و`flutter test` (56/56 ناجح) الموثَّقين أعلاه، إضافة لتوثيق `docs/PROGRESS_REPORT.md` لبناء ناجح سابق على جهاز حقيقي (SM A536E, Android 15) بعد حل مشاكل بيئة مشابهة (JDK 17، Android SDK 36).

---

## 8. الإحصائيات (Statistics)

### عدد الملفات حسب النوع (عدّ فعلي عبر `find`، مستثنياً `build/`, `.dart_tool/`, `.git/`)
| النوع | العدد |
|---|---|
| `.dart` | 94 (منها 85 تحت `lib/`، 7 تحت `test/`، والباقي ملفات تهيئة إضافية مثل ملفات web/tool) |
| `.png` | 43 |
| `.xml` | 17 |
| `.log` | 17 |
| `.json` | 14 |
| `.md` | 11 |
| ملفات أخرى | `.bin`(7), `.properties`(6), `.plist`(6), `.lock`(6), `.xcconfig`(3), `.js`(3), `.gradle`(3), `.gitignore`(3), `.yaml`(2), وملفات iOS/رسومات متفرقة أقل من ذلك |

### إجمالي أسطر كود Dart
- **ملفات `.dart` تحت `lib/`:** 85 ملفاً
- **إجمالي أسطر Dart في `lib/`:** **15,246 سطراً** (عدّ فعلي عبر `wc -l` على كل ملفات `.dart` تحت `lib/`، شامل التعليقات والأسطر الفارغة)
- **ملفات الاختبار:** 7 ملفات، 665 سطراً

### هل هو مستودع git؟
**نعم — هذا الريبو مستودع git فعلي حالياً** (تم التحقق فعلياً بـ `git status` من `D:\Shadow\app`؛ هذا يتناقض مع الافتراض الوارد في تعليمات هذه المهمة بأنه "لم يكن مستودع git كما تم التحقق مؤخراً" — على الأرجح كان ذلك صحيحاً وقت `docs/AUDIT.md` الأصلي (2026-07-24، الذي وثّق صراحة "لا يوجد git repo")، ثم أُنشئ لاحقاً كأول إصلاح بنيوي موثَّق في `docs/PROGRESS_REPORT.md`).
- **عدد الـ commits:** 72 (عدّ فعلي عبر `git log --oneline | wc -l`)
- **الفرع الحالي:** `main`
- **آخر commit:** `0f3be40` — "feat(home): full redesign to the new design-token spec ("echo" layer, primary card, wave animation)" بتاريخ **2026-08-16 20:47:26 +0800**
- **حالة شجرة العمل وقت هذا التقرير:** **غير نظيفة** — 14 ملفاً معدَّلاً وملف واحد محذوف (`lib/pages/dev_tools/dev_tools_page.dart`) لم يُعمَل لها commit بعد، بالإضافة لملف/مجلد جديد غير متتبَّع (`android/app/src/debug/res/`). الفرع المحلي متقدّم عن `origin/main` بـ 4 commits (لم يُدفَع/`push` بعد).

---

## 9. الحالة الحقيقية (Real state)

هذا القسم مبني بشكل أساسي على القراءة المباشرة لتوثيق داخلي مؤرَّخ وموقَّع صراحة بأنه "مبني على تحقّق فعلي، وليس افتراضاً" (`docs/FINAL_STATUS_APP.md`، 2026-08-13، و`docs/PROGRESS_REPORT.md`، 2026-07-28)، مقروء بالكامل في هذه الجلسة، بالإضافة إلى فحص مباشر للكود الحالي.

### ما هو مكتمل ومؤكَّد يعمل فعلياً (بدليل اختبار مباشر على جهاز موثَّق في `docs/`)
- **وضع الصمم (Deepgram streaming):** بدء/إيقاف التسجيل، إذن الميكروفون، ظهور نص حي، حفظ/نسخ/مسح التفريغ، شاشة النصوص المحفوظة — اختُبرت فعلياً على جهاز حقيقي (SM A536E, Android 15) حسب `docs/PROGRESS_REPORT.md`، مع أعطال حقيقية أُصلحت (401 بسبب توكن في الرابط، 400 بسبب موديل غير مدعوم للعربية، توقّف فوري بسبب استدعاء مزدوج).
- **إصلاحات UI موثَّقة باختبار مباشر على جهاز في جلسة 2026-08-13:** قصّ عنوان الشاشة (سببه الفعلي: عدم تغليف الرأس بـ `SafeArea`، وليس الخط كما افتُرض أول مرة)، زر "اقرأ لي" (TTS) الذي كان لا يتوقف (`awaitSpeakCompletion` لم يكن مفعَّلاً)، قصّ حروف عربية طويلة (ش/ت/ل) عند حجم خط كبير، زر "خيارات" الذي بقي عربياً في الوضع الإنجليزي.
- **زر "اتصال سريع" الحقيقي** (بدل زر "طوارئ" الوهمي القديم) — مؤكَّد بالكود الحالي (`_quickContact` في `physical_assistance_mode_widget.dart` يستدعي `url_launcher` فعلياً بعد تأكيد المستخدم)، وموثَّق في `docs/BACKLOG.md` كبند "✅ RESOLVED".
- **إغلاق قواعد Firestore/Storage** (كانت مفتوحة بالكامل `if true`، أصبحت `if false`) — مؤكَّد بقراءة مباشرة لملف `firebase/firestore.rules` الحالي.
- **56/56 اختبار ناجح** و**0 أخطاء تحليل** — مؤكَّد بتشغيل فعلي لـ`flutter test`/`flutter analyze` في هذه الجلسة تحديداً.

### ما هو مبني بالكود لكن غير مؤكَّد على جهاز حقيقي (موثَّق صراحة كفجوة في `docs/`)
- **"تذكرني" (Remember Me):** مكتملة بالكود، مغطاة بـ5 اختبارات محاكاة تمر جميعها، لكن **المستخدم أبلغ صراحة أنها لا تعمل فعلياً على جهاز حقيقي** (`docs/FINAL_STATUS_APP.md`) ولم يُعثَر على السبب الجذري. أُضيف تسجيل تشخيصي فقط، لا إصلاح مؤكَّد.
- **دقّة Deepgram (Word Error Rate) على محاضرة جامعية حقيقية — لم تُقَس إطلاقاً حتى تاريخ آخر توثيق داخلي.** هذه أهم نقطة مفتوحة في المشروع بأكمله حسب `AGENTS.md` نفسه ("Nobody has tested this on real audio… the entire product depends on it") وأداة القياس (`tool/asr_spike/`) جاهزة لكن غير مُشغَّلة على تسجيل فعلي.
- **جودة مخرجات Gemini الفعلية** (وصف الصور، تبسيط PDF) بعد التحويل الأخير من Kimi — لا تأكيد ميداني صريح موثَّق أن استدعاء Gemini الحقيقي أرجع نتيجة عربية صحيحة على جهاز.
- **الوضع الليلي (Dark mode):** مكتمل بالكود وتحقّق تباين WCAG برمجياً، لكن **لم يُختبَر بصرياً على جهاز حقيقي** حسب التوثيق الداخلي نفسه.
- **محرك التكيّف (المراحل 3-5: تكيّف حجم خط، تلخيص دوري، سجل المرشد المحلي):** مبني ومختبَر منطقياً بوحدات اختبار مؤقتة (لاحقاً محذوفة حسب `docs/PROGRESS_REPORT.md`)، لكن **لم يُشاهَد فعلياً على شاشة جهاز حقيقي** أن تغيّر الملف الشخصي ينعكس على الواجهة كما هو متوقَّع.
- **إعادة التصميم البصري الأخيرة (آخر 5 commits، الشاشة الرئيسية بتصميم "echo layer")** — هذا العمل لاحق زمنياً لآخر تقرير حالة مقروء (`FINAL_STATUS_APP.md`، 2026-08-13)، ولا يوجد توثيق داخلي يؤكد اختباره على جهاز حقيقي.

### ما هو معطَّل/معلَّق عمداً في الكود، مع السبب الموثَّق
- **Firestore/Firebase:** مقفل بالكامل (`allow read, write: if false`) عمداً بعد تحقّق أن لا كود يستخدمه — القرار موثَّق داخل ملف القواعد نفسه، مع تعليمة صريحة: "do NOT reopen with 'if true'" عند بناء منصة حقيقية لاحقاً.
- **`google-services` Gradle plugin:** عُطِّل مؤقتاً في مرحلة سابقة (commit موثَّق `7124ddd` في `docs/PROGRESS_REPORT.md`) لحل مشكلة بناء متعلّقة بتهيئة Firebase على جهاز جديد؛ `initFirebase()` أصبح محروساً (guarded) بدل تعطيل التطبيق بالكامل. مُعلَّم صراحة "TEMP" في رسالة الـ commit حسب التوثيق.
- **توقيع APK:** لا يزال يستخدم مفتاح debug للبناء الإصداري (`android/app/build.gradle`، `signingConfig signingConfigs.debug` مع تعليق `// TODO: Add your own signing config for the release build.`) — مناسب للاختبار/التوزيع الجانبي فقط، غير صالح لمتجر Play.
- **دعم iOS:** خارج النطاق بقرار سابق لصاحب المشروع حسب `docs/PROGRESS_REPORT.md`؛ ملفات iOS موجودة في الشجرة (`ios/`, `GoogleService-Info.plist` مذكور في README كملف مطلوب) لكن غير مُختبَرة أو مُستهدَفة فعلياً.

### بحث شامل عن TODO/FIXME/HACK
تم البحث في كل ملفات `lib/` و`test/` (`grep -rn "TODO\|FIXME\|HACK"`). النتائج الكاملة (3 مطابقات فقط، كلها في ملف واحد):

- `lib/services/mentor_log.dart:14` — "TODO(pdpl-review) markers at the two functions that would feed a future [sync]"
- `lib/services/mentor_log.dart:190` — "TODO(pdpl-review): before this is ever wired to a network call, get legal [review]"
- `lib/services/mentor_log.dart:207` — "TODO(pdpl-review): same PDPL review requirement as unsyncedEvents() above"

هذه الثلاثة كلها في سياق واحد: سجل المرشد المحلي (`mentor_log.dart`) مبني الآن كتخزين محلي فقط بلا رفع لأي خادم، وواضعو الكود تركوا علامات صريحة أنه **قبل** ربط هذا السجل مستقبلاً بأي اتصال شبكي، يجب أولاً مراجعة قانونية بموجب نظام حماية البيانات الشخصية السعودي (PDPL) — وهذا قرار نطاق واعٍ موثَّق، وليس ديناً تقنياً منسياً. بالإضافة، `android/app/build.gradle` يحوي TODO منفصلَين (تغيير Application ID، وإضافة توقيع إصدار حقيقي) — مذكوران في README كنقطة معروفة أيضاً.

### التوثيق الداخلي (`docs/`, `AGENTS.md`, `README.md`) — ملخص كل ملف قُرئ فعلياً

| الملف | التاريخ | الملخص |
|---|---|---|
| `AGENTS.md` (جذر المشروع) | آخر إعادة كتابة موثَّقة 2026-07-24 | "مصدر الحقيقة" لقواعد العمل في الريبو: يمنع صراحة الهجرة لـRiverpod/بنية مجلدات مختلفة/تغيير مزوّد AI بلا إذن؛ يحدد أولويات عمل (git، Firestore، زر الطوارئ، إلخ)؛ **يحتوي معلومة متأخرة عن الواقع** (يذكر Kimi كمزوّد AI رغم أن الكود يستخدم Gemini الآن). |
| `README.md` | آخر تعديل 2026-08-02 (ملف) | إرشادات إعداد وتشغيل: ملفات Firebase المطلوبة غير المتتبَّعة، تهيئة `env.json`، شرح تكامل المنصة، أوامر البناء والتشغيل. لا يزال يحمل عنوان "UniAccess" القديم ويذكر `OPENAI_API_KEY` كمثال قديم غير مطابق لـ`env.example.json` الفعلي. |
| `docs/AUDIT.md` | 2026-07-24 | تدقيق أولي شامل (قبل أي إصلاح) وجد: لا git، Firestore مفتوح بالكامل، زر طوارئ وهمي، صفر Semantics، لا ترجمة/RTL حقيقيين، مزوّد AI كان OpenAI GPT-4o وقتها. أساس كل الإصلاحات اللاحقة. |
| `docs/BACKLOG.md` | 2026-07-24 | بندان عاليا الأولوية (Semantics، زر الطوارئ) — كلاهما ✅ RESOLVED الآن حسب الملف نفسه؛ علّتان معروفتان (RenderFlex overflow، فشل PDF من OneDrive) — كلاهما موثَّق كمُصلَح لاحقاً في تقارير أحدث. |
| `docs/PROGRESS_REPORT.md` | 2026-07-28 | تقرير فهم شامل لأول 47 commit: حل مشاكل بيئة البناء على جهاز حقيقي، تهيئة git، إغلاق قواعد Firebase، رحلة مزوّد AI (OpenAI→Kimi→Gemini)، بناء محرك التكيّف بمراحله الخمس، صراحة كاملة أن أغلب الطبقة "الذكية" (جودة Gemini/دقة Deepgram) لم تُختبَر ميدانياً بعد. |
| `docs/FINAL_STATUS_APP.md` | 2026-08-13 | أحدث تقرير حالة شامل مقروء في هذه الجلسة، مبني صراحة على تشغيل فعلي لأوامر في جلسته: 56/56 اختبار ناجح، 0 أخطاء تحليل، تفصيل دقيق لكل وضع وما اختُبر فعلياً على جهاز مقابل ما لم يُختبَر، فجوة "تذكرني" غير المحلولة، 5 شاشات غير مترجَمة وقتها، وتأكيد أن قياس دقة Deepgram لا يزال أهم نقطة مفتوحة في المشروع. |
| `docs/ROADMAP.md` | لم تُقرأ محتوياته بالتفصيل في هذه الجلسة (153 سطراً موجودة) | حسب الإشارات المتكررة له في `AGENTS.md`/التقارير الأخرى: يوثّق أن منصة الجامعة (Phase 2: مصادقة كاملة، تعدد مستأجرين، لوحات مشرف) في ريبو منفصل تماماً وخارج نطاق هذا المستودع عمداً. |
| `docs/شادو_خطة_التكيف_الشاملة.md` | لم تُقرأ محتوياته بالتفصيل في هذه الجلسة (284 سطراً موجودة) | حسب الإشارة له في `docs/FINAL_STATUS_APP.md`: الوثيقة المصدرية التي بُني عليها محرك التكيّف بمراحله الخمس (StudentProfile، تكيّف برومبتات AI، تكيّف كودي، طبقة تصنيف موحّدة، سجل مرشد). |
| `docs/ACCESSIBILITY_TESTING.md` | لم تُقرأ محتوياته بالتفصيل في هذه الجلسة (67 سطراً موجودة) | حسب الإشارة له في `docs/PROGRESS_REPORT.md`: دليل لاختبار TalkBack يدوياً على كل شاشة — "دليل جاهز، لا شهادة اختبار مكتمل" (لا تأكيد أن أحداً نفّذه فعلياً وأبلغ بالنتيجة). |

---

## ما لم أستطع التحقق منه (What I could not verify)

- **نتيجة `flutter build apk --debug` نهائية غير مؤكَّدة كـ"عابرة أم متكررة":** البناء نُفِّذ فعلياً وفشل بخطأ قفل ملفات Windows (`cleanMergeDebugAssets`، انظر القسم 7) — لم يُعَد تشغيله بعد الفشل للتأكد من أن السبب عابر (قفل مؤقت من عملية أخرى) وليس عطلاً بيئياً متكرراً؛ لا حجم/مسار APK فعلي تم إنتاجه للتحقق منه.
- **لا يمكنني تأكيد أن المفاتيح الفعلية داخل `env.json` صالحة/تعمل** — لم تُقرأ قيمها ولم تُختبَر شبكياً.
- **لم أختبر التطبيق فعلياً على جهاز أو محاكي** — كل ما ورد عن "اختُبر على جهاز حقيقي" في القسم 9 منقول حرفياً من توثيق داخلي مؤرَّخ (`docs/FINAL_STATUS_APP.md`, `docs/PROGRESS_REPORT.md`)، وليس ملاحظة مباشرة مني في هذه الجلسة.
- **حالة ميزة "تذكرني" الفعلية اليوم** غير مؤكَّدة — آخر توثيق (2026-08-13) يقول إنها لا تعمل على جهاز حقيقي رغم اجتياز الاختبارات؛ لا يوجد توثيق أحدث يؤكد إصلاحها أو استمرار العطل حتى تاريخ هذا التقرير.
- **دقة Deepgram (WER) على محاضرة حقيقية** لا تزال — حسب كل التوثيق المتاح — غير مقيسة إطلاقاً؛ لم أستطع تشغيل `tool/asr_spike/` بنفسي (يحتاج تسجيل صوتي حقيقي ومفاتيح API فعلية).
- **جودة مخرجات Gemini الفعلية** (وصف صور/تبسيط PDF حقيقي) غير مؤكَّدة ميدانياً حسب آخر توثيق متاح، ولم أستطع تشغيل استدعاء Gemini فعلي في هذه الجلسة (بلا مفتاح مكشوف ولا جهاز).
- **محتوى `docs/ROADMAP.md`, `docs/شادو_خطة_التكيف_الشاملة.md`, `docs/ACCESSIBILITY_TESTING.md` بالتفصيل الكامل** — عُرفت أطوالها فقط (153، 284، 67 سطراً على التوالي) والغرض العام منها استُنتِج من إشارات إليها في تقارير أخرى مقروءة بالكامل، لا من قراءة مباشرة لكل سطر فيها.
- **ما إذا كانت شجرة العمل غير المُثبَّتة الحالية (14 ملفاً معدَّلاً + حذف `dev_tools`) تمثّل عملاً منتهياً وجاهزاً للـcommit أم عملاً جارياً غير مكتمل** — لا يوجد توثيق داخلي يؤكد أياً من الاحتمالين حتى تاريخ هذا التقرير.
- **ما إذا كان `d:\Shadow\_backup_old\UniAccess` (نسخة قديمة مذكورة في `docs/AUDIT.md`) لا يزال موجوداً أو ذا صلة** — لم يُفحَص في هذه الجلسة (خارج نطاق `D:\Shadow\app`).
- **اختبار TalkBack الفعلي على جهاز حقيقي** — لا تأكيد أنه نُفِّذ فعلياً وأُبلغ بنتيجته، رغم وجود دليل جاهز (`docs/ACCESSIBILITY_TESTING.md`).
