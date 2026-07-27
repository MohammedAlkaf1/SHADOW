// Saved transcripts screen: list, open, delete single, delete all, and set the
// auto-expiry retention period. All data is local (sqflite); nothing leaves the
// device. Pushed with Navigator (not wired into FlutterFlow routing) to avoid
// touching generated nav code.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/a11y.dart';
import '/theme.dart';
import '/services/app_prefs.dart';
import '/services/transcript_store.dart';

class SavedTranscriptsPage extends StatefulWidget {
  const SavedTranscriptsPage({super.key});

  @override
  State<SavedTranscriptsPage> createState() => _SavedTranscriptsPageState();
}

class _SavedTranscriptsPageState extends State<SavedTranscriptsPage> {
  List<Transcript> _items = [];
  int _retentionDays = AppPrefs.defaultRetentionDays;
  bool _loading = true;

  static const _retentionOptions = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _retentionDays = await AppPrefs.getRetentionDays();
    // Enforce expiry whenever the list is opened.
    await TranscriptStore.instance.purgeExpired(_retentionDays);
    final items = await TranscriptStore.instance.listAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} - ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _confirmDeleteOne(Transcript t) async {
    final ok = await _confirm('حذف هذا النص؟');
    if (ok) {
      await TranscriptStore.instance.delete(t.id);
      await _load();
    }
  }

  Future<void> _confirmDeleteAll() async {
    if (_items.isEmpty) return;
    final ok = await _confirm('حذف جميع النصوص المحفوظة؟ لا يمكن التراجع.');
    if (ok) {
      await TranscriptStore.instance.deleteAll();
      await _load();
    }
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        content: Text(message,
            textAlign: TextAlign.end, style: AppText.body()),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: AppText.button(color: AppColors.mutedOnCream)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: AppText.button(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openViewer(Transcript t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.pill),
                ),
              ),
              Text(_formatDate(t.createdAt),
                  textAlign: TextAlign.end, style: AppText.label()),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    t.text,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.tajawal(
                        fontSize: 18.0,
                        height: 1.7,
                        color: AppColors.onCream),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              a11yButton(
                label: 'نسخ النص',
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.onNavy,
                    minimumSize: const Size.fromHeight(AppSpacing.minTap),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: t.text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ النص',
                            textAlign: TextAlign.end, style: AppText.body(color: AppColors.onNavy)),
                        backgroundColor: AppColors.navy,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text('نسخ',
                      style: AppText.button(color: AppColors.onNavy)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editRetention() async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text('مدة الاحتفاظ بالنصوص',
            textAlign: TextAlign.end, style: AppText.title()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _retentionOptions
              .map((days) => RadioListTile<int>(
                    value: days,
                    groupValue: _retentionDays,
                    activeColor: AppColors.terracotta,
                    onChanged: (v) => Navigator.pop(ctx, v),
                    title: Text('$days يوماً',
                        textAlign: TextAlign.end, style: AppText.body()),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen != null) {
      await AppPrefs.setRetentionDays(chosen);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.onCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: AppColors.onCream),
        title: Text('النصوص المحفوظة', style: AppText.title()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          a11yButton(
            label: 'حذف كل النصوص',
            enabled: _items.isNotEmpty,
            child: IconButton(
              icon: Icon(Icons.delete_sweep_rounded,
                  color: _items.isEmpty
                      ? AppColors.mutedOnCream
                      : AppColors.error),
              onPressed: _items.isEmpty ? null : _confirmDeleteAll,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))
          : Column(
              children: [
                // Retention setting row
                a11yButton(
                  label: 'مدة الاحتفاظ، $_retentionDays يوماً، اضغط للتغيير',
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.auto_delete_outlined,
                        color: AppColors.terracotta),
                    title: Text('حذف تلقائي بعد $_retentionDays يوماً',
                        textAlign: TextAlign.end, style: AppText.body()),
                    subtitle: Text('تُحذف النصوص الأقدم تلقائياً',
                        textAlign: TextAlign.end, style: AppText.label()),
                    onTap: _editRetention,
                  ),
                ),
                Container(height: 1, color: AppColors.border),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text('لا توجد نصوص محفوظة',
                              style: AppText.body(color: AppColors.mutedOnCream)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => Container(
                              height: 1,
                              color: AppColors.border,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md)),
                          itemBuilder: (ctx, i) {
                            final t = _items[i];
                            return a11yButton(
                              label:
                                  '${t.preview}، ${_formatDate(t.createdAt)}',
                              child: ListTile(
                                title: Text(t.preview,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body().copyWith(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(_formatDate(t.createdAt),
                                    textAlign: TextAlign.end,
                                    style: AppText.label()),
                                trailing: a11yButton(
                                  label: 'حذف',
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error),
                                    onPressed: () => _confirmDeleteOne(t),
                                  ),
                                ),
                                onTap: () => _openViewer(t),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
