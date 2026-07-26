import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/theme.dart';
import 'dart:ui' as ui;
import '/custom_code/actions/index.dart' as actions;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'learning_support_mode_model.dart';
export 'learning_support_mode_model.dart';

class LearningSupportModeWidget extends StatefulWidget {
  const LearningSupportModeWidget({super.key});

  static String routeName = 'LearningSupportMode';
  static String routePath = '/learningSupportMode';

  @override
  State<LearningSupportModeWidget> createState() =>
      _LearningSupportModeWidgetState();
}

class _LearningSupportModeWidgetState extends State<LearningSupportModeWidget> {
  late LearningSupportModeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LearningSupportModeModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textAlign: TextAlign.end, style: AppText.body(color: AppColors.onNavy)),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPdfFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // load bytes so cloud files (no local path) still work
      );
    } catch (e) {
      // Cloud-backed files (e.g. OneDrive) can throw PlatformException.
      debugPrint('file_picker failed: $e');
      _snack(
          'تعذّر فتح الملف. اختر ملف PDF محفوظاً على الجهاز (وليس من التخزين السحابي مثل OneDrive).');
      return;
    }
    if (result == null) return; // user cancelled

    final file = result.files.single;
    if (file.bytes == null) {
      _snack(
          'تعذّر فتح الملف. اختر ملف PDF محفوظاً على الجهاز (وليس من التخزين السحابي مثل OneDrive).');
      return;
    }
    safeSetState(() {
      _model.pdfFilePath = null;
      _model.pdfFileBytes = file.bytes;
      _model.currentDocName = '"${file.name}"';
      _model.aiResult = null;
      _model.extractedText = null;
    });
  }

  Future<void> _processDocument(String mode) async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    if (_model.pdfFileBytes == null) {
      _snack('يرجى اختيار ملف PDF أولاً');
      return;
    }

    safeSetState(() {
      _model.isProcessing = true;
      _model.aiResult = null;
    });

    final result = await actions.processDocumentWithGpt4o(
      fileBytes: _model.pdfFileBytes,
      mode: mode,
    );

    safeSetState(() {
      _model.isProcessing = false;
      _model.aiResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final hasDoc = (_model.pdfFileBytes != null);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: AppColors.cream,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header('دعم التعلم', Icons.psychology_rounded),
              Expanded(
                child: SingleChildScrollView(
                  primary: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Upload card
                        Container(
                          decoration: AppDecor.navyCard(),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              children: [
                                const Icon(Icons.cloud_upload_rounded,
                                    color: AppColors.onNavy, size: 48.0),
                                const SizedBox(height: AppSpacing.md),
                                Text('رفع ملف PDF للمحاضرة',
                                    textAlign: TextAlign.center,
                                    style: AppText.cardTitle()),
                                const SizedBox(height: AppSpacing.lg),
                                a11yButton(
                                  label: 'اختر ملفاً',
                                  child: Material(
                                    color: AppColors.terracotta,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.pill),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: _pickPdfFile,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xl,
                                            vertical: 12.0),
                                        child: Text('اختر ملفاً',
                                            style: AppText.button(
                                                color: AppColors.onNavy)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Loaded file name
                        if (hasDoc) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Icon(Icons.description_outlined,
                                  size: 18.0, color: AppColors.mutedOnCream),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _model.currentDocName ?? '',
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.label(color: AppColors.onCream),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        // Assistant section title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('المساعد الذكي',
                                style: AppText.body(color: AppColors.onCream)),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.auto_awesome_rounded,
                                color: AppColors.terracotta, size: 18.0),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Assistant buttons
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _AiActionButton(
                                  label: 'تلخيص',
                                  icon: Icons.summarize_rounded,
                                  isLoading: _model.isProcessing,
                                  onTap: () => _processDocument('summarize'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _AiActionButton(
                                  label: 'تبسيط',
                                  icon: Icons.lightbulb_outline_rounded,
                                  isLoading: _model.isProcessing,
                                  onTap: () => _processDocument('simplify'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _AiActionButton(
                                  label: 'أسئلة مراجعة',
                                  icon: Icons.quiz_rounded,
                                  isLoading: _model.isProcessing,
                                  onTap: () => _processDocument('quiz'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Loading / result
                        if (_model.isProcessing) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            decoration: AppDecor.creamCard(),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: AppColors.terracotta),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text('جارٍ المعالجة...',
                                      style: AppText.body()),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_model.aiResult != null && !_model.isProcessing) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            decoration: AppDecor.creamCard(),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('النتيجة',
                                          style: AppText.body(
                                              color: AppColors.onCream)),
                                      const SizedBox(width: AppSpacing.sm),
                                      const Icon(Icons.auto_awesome_rounded,
                                          color: AppColors.terracotta,
                                          size: 18.0),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  a11yLive(Text(
                                    _model.aiResult!,
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.tajawal(
                                      color: AppColors.onCream,
                                      fontSize:
                                          FFAppState().readingFontSize < 18.0
                                              ? 18.0
                                              : FFAppState().readingFontSize,
                                      height: 1.6,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Font-size slider panel (single label — no duplicate)
              _sliderPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title, IconData icon) {
    return Container(
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
                  label: 'رجوع',
                  child: SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.onCream, size: 22.0),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, color: AppColors.terracotta, size: 22.0),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title,
                      textAlign: TextAlign.end, style: AppText.title()),
                ),
              ],
            ),
          ),
          Container(height: 1.0, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _sliderPanel() {
    final size = FFAppState().readingFontSize.clamp(14.0, 32.0);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.lg),
          topRight: Radius.circular(AppSpacing.lg),
        ),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('حجم الخط', style: AppText.body(color: AppColors.onCream)),
                Text('${size.round()}',
                    style: AppText.body(color: AppColors.terracotta)),
              ],
            ),
            Slider(
              activeColor: AppColors.terracotta,
              inactiveColor: AppColors.border,
              value: size,
              min: 14.0,
              max: 32.0,
              divisions: 9,
              label: '${size.round()}',
              onChanged: (val) {
                FFAppState().update(() {
                  FFAppState().readingFontSize = val;
                });
                safeSetState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AiActionButton extends StatelessWidget {
  const _AiActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return a11yButton(
      enabled: !isLoading,
      child: Opacity(
        opacity: isLoading ? 0.5 : 1.0,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.navy, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md, horizontal: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.navy, size: 24.0),
                  const SizedBox(height: 6.0),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppText.label(color: AppColors.navy),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
