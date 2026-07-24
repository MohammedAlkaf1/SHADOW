// Saved transcripts screen: list, open, delete single, delete all, and set the
// auto-expiry retention period. All data is local (sqflite); nothing leaves the
// device. Pushed with Navigator (not wired into FlutterFlow routing) to avoid
// touching generated nav code.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        content: Text(message,
            textAlign: TextAlign.end, style: GoogleFonts.cairo(fontSize: 16.0)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_formatDate(t.createdAt),
                    textAlign: TextAlign.end,
                    style: GoogleFonts.cairo(
                        color: FlutterFlowTheme.of(context).secondaryText)),
                const SizedBox(height: 12.0),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(
                      t.text,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.cairo(fontSize: 18.0, height: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                a11yButton(
                  label: 'نسخ النص',
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: FlutterFlowTheme.of(context).onPrimary,
                      minimumSize: const Size.fromHeight(48.0),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: t.text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ النص',
                              textAlign: TextAlign.end,
                              style: GoogleFonts.cairo()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy_rounded),
                    label: Text('نسخ',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editRetention() async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: Text('مدة الاحتفاظ بالنصوص',
              textAlign: TextAlign.end,
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18.0)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _retentionOptions
                .map((days) => RadioListTile<int>(
                      value: days,
                      groupValue: _retentionDays,
                      onChanged: (v) => Navigator.pop(ctx, v),
                      title: Text('$days يوماً',
                          textAlign: TextAlign.end, style: GoogleFonts.cairo()),
                    ))
                .toList(),
          ),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          foregroundColor: FlutterFlowTheme.of(context).primaryText,
          title: Text('النصوص المحفوظة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          actions: [
            a11yButton(
              label: 'حذف كل النصوص',
              enabled: _items.isNotEmpty,
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: _items.isEmpty ? null : _confirmDeleteAll,
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Retention setting row
                  a11yButton(
                    label: 'مدة الاحتفاظ، $_retentionDays يوماً، اضغط للتغيير',
                    child: ListTile(
                      leading: Icon(Icons.auto_delete_outlined,
                          color: FlutterFlowTheme.of(context).primary),
                      title: Text('حذف تلقائي بعد $_retentionDays يوماً',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.cairo()),
                      subtitle: Text('تُحذف النصوص الأقدم تلقائياً',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.cairo(fontSize: 12.0)),
                      onTap: _editRetention,
                    ),
                  ),
                  const Divider(height: 1.0),
                  Expanded(
                    child: _items.isEmpty
                        ? Center(
                            child: Text('لا توجد نصوص محفوظة',
                                style: GoogleFonts.cairo(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText)),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1.0),
                            itemBuilder: (ctx, i) {
                              final t = _items[i];
                              return a11yButton(
                                label: '${t.preview}، ${_formatDate(t.createdAt)}',
                                child: ListTile(
                                  title: Text(t.preview,
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(_formatDate(t.createdAt),
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.cairo(fontSize: 12.0)),
                                  trailing: a11yButton(
                                    label: 'حذف',
                                    child: IconButton(
                                      icon: Icon(Icons.delete_outline_rounded,
                                          color:
                                              FlutterFlowTheme.of(context).error),
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
      ),
    );
  }
}
