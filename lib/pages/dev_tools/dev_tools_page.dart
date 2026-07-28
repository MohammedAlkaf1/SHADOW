// Developer-only screen: lets you switch the active StudentProfile
// (category + support level) live, without restarting the app, so later
// phases (Gemini prompt adaptation, mode-UI adaptation) can be tested
// against every combination. Never reachable in a release build — both the
// entry point and this screen itself are gated behind kDebugMode.
//
// This is NOT part of the four student-facing modes; it is a testing tool
// for the person building the adaptation engine.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/a11y.dart';
import '/services/mentor_log.dart';
import '/theme.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';

// Arabic labels now come from StudentCategoryArabic/SupportLevelArabic in
// student_profile.dart (single source, shared with the adaptive Gemini
// prompts in adaptive_prompts.dart) instead of a local copy here.

class DevToolsPage extends StatelessWidget {
  const DevToolsPage({super.key});

  static String routeName = 'DevTools';
  static String routePath = '/devTools';

  @override
  Widget build(BuildContext context) {
    // Defensive: even though the only entry point is itself debug-gated,
    // never render real content here in a release build.
    if (!kDebugMode) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.onCream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          leading: a11yButton(
            label: 'رجوع',
            child: IconButton(
              icon: appBackIcon(context),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          title: Text('أدوات المطوّر', style: AppText.title()),
          bottom: TabBar(
            labelColor: AppColors.terracotta,
            unselectedLabelColor: AppColors.mutedOnCream,
            indicatorColor: AppColors.terracotta,
            labelStyle: AppText.label(),
            tabs: const [
              Tab(text: 'الملف الشخصي'),
              Tab(text: 'أحداث المرشد'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProfileTab(),
            _MentorEventsTab(),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProfileProvider>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _banner(),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle('التصنيف العام (Category)'),
        const SizedBox(height: AppSpacing.sm),
        _card(
          child: Column(
            children: StudentCategory.values
                .map((c) => _categoryTile(context, provider, c))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle('مستوى الدعم (Support level)'),
        const SizedBox(height: AppSpacing.sm),
        _card(
          child: Column(
            children: SupportLevel.values
                .map((l) => _supportLevelTile(context, provider, l))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'يعيد --dart-define=STUDENT_CATEGORY=... و '
          '--dart-define=STUDENT_SUPPORT_LEVEL=... ضبط القيمة الافتراضية '
          'عند تشغيل التطبيق فقط؛ التبديل هنا مؤقت لهذه الجلسة.',
          textAlign: TextAlign.end,
          style: AppText.label(),
        ),
      ],
    );
  }

  Widget _banner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.science_outlined, color: AppColors.terracotta),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'أدوات اختبار داخلية — لا تظهر في نسخة الإصدار (release).',
                textAlign: TextAlign.end,
                style: AppText.body(color: AppColors.onNavy),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text) =>
      Text(text, textAlign: TextAlign.end, style: AppText.cardTitle(color: AppColors.onCream));

  Widget _card({required Widget child}) => Container(
        decoration: AppDecor.creamCard(),
        child: child,
      );

  // Bare RadioListTile (no a11yButton wrap): RadioListTile already exposes
  // correct radio-button semantics on its own, which a11yButton's
  // Semantics(button: true) would override with a plain "button" role.
  Widget _categoryTile(
    BuildContext context,
    StudentProfileProvider provider,
    StudentCategory value,
  ) {
    return RadioListTile<StudentCategory>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: provider.category,
      activeColor: AppColors.terracotta,
      // ignore: deprecated_member_use
      onChanged: (v) {
        if (v != null) provider.setCategory(v);
      },
      // excludeSemantics: the visible two-line title (name + conditions)
      // would otherwise be read with Flutter's default multi-Text join;
      // this gives TalkBack the exact "name — conditions" phrasing a
      // (possibly blind) advisor needs.
      title: Semantics(
        label: '${value.arabicLabel} — ${value.conditions}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.arabicLabel,
              textAlign: TextAlign.end,
              style: AppText.body(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value.conditions,
              textAlign: TextAlign.end,
              style: AppText.caption(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportLevelTile(
    BuildContext context,
    StudentProfileProvider provider,
    SupportLevel value,
  ) {
    return RadioListTile<SupportLevel>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: provider.supportLevel,
      activeColor: AppColors.terracotta,
      // ignore: deprecated_member_use
      onChanged: (v) {
        if (v != null) provider.setSupportLevel(v);
      },
      title: Text(
        value.arabicLabel,
        textAlign: TextAlign.end,
        style: AppText.body(),
      ),
    );
  }
}

/// Last 50 MentorEvent rows, filterable by severity, with a clear-all
/// button — the only verification surface for Phase 5 right now (no mentor
/// screen, no upload, no mentor auth exist yet).
class _MentorEventsTab extends StatefulWidget {
  const _MentorEventsTab();

  @override
  State<_MentorEventsTab> createState() => _MentorEventsTabState();
}

class _MentorEventsTabState extends State<_MentorEventsTab> {
  EventSeverity? _filter;
  List<MentorEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final events = await MentorLog.instance.recent(limit: 50, severity: _filter);
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text('مسح كل الأحداث',
            textAlign: TextAlign.end, style: AppText.title()),
        content: Text('سيُحذف كل سجل MentorEvent محلياً. لا يمكن التراجع.',
            textAlign: TextAlign.end, style: AppText.body()),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: AppText.button(color: AppColors.navy)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('مسح', style: AppText.button(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await MentorLog.instance.clearAll();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: AppColors.error, size: 18),
                    label: Text('امسح كل الأحداث',
                        style: AppText.label(color: AppColors.error)),
                  ),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 18, color: AppColors.mutedOnCream),
                    label: Text('تحديث', style: AppText.label()),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _severityFilterRow(),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.terracotta))
              : _events.isEmpty
                  ? Center(
                      child: Text('لا توجد أحداث بعد',
                          style: AppText.body(color: AppColors.mutedOnCream)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      itemCount: _events.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, i) => _eventTile(_events[i]),
                    ),
        ),
      ],
    );
  }

  Widget _severityFilterRow() {
    Widget chip(String label, EventSeverity? value) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(label,
              style: AppText.label(
                  color: selected ? AppColors.onNavy : AppColors.onCream)),
          selected: selected,
          selectedColor: AppColors.navy,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          onSelected: (_) {
            setState(() => _filter = value);
            _load();
          },
        ),
      );
    }

    return Row(
      children: [
        chip('الكل', null),
        chip('فوري', EventSeverity.immediate),
        chip('أسبوعي', EventSeverity.weekly),
        chip('معلومة', EventSeverity.info),
      ],
    );
  }

  Widget _eventTile(MentorEvent e) {
    final sevColor = switch (e.severity) {
      EventSeverity.immediate => AppColors.error,
      EventSeverity.weekly => AppColors.terracotta,
      EventSeverity.info => AppColors.mutedOnCream,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecor.creamCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.pill),
                ),
                child: Text(e.severity.name, style: AppText.label(color: sevColor)),
              ),
              Text(_formatTimestamp(e.timestamp), style: AppText.label()),
            ],
          ),
          const SizedBox(height: 4),
          Text(e.eventType.name,
              textAlign: TextAlign.end,
              style: AppText.body().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            '${e.mode} · ${e.studentCategory.arabicLabel} · ${e.supportLevel.arabicLabel}',
            textAlign: TextAlign.end,
            style: AppText.label(),
          ),
          if (e.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(e.details.toString(),
                textAlign: TextAlign.end, style: AppText.label()),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}
