// Saved transcripts screen: list, open, delete single, delete all, and set the
// auto-expiry retention period. All data is local (sqflite); nothing leaves the
// device. Pushed with Navigator (not wired into FlutterFlow routing) to avoid
// touching generated nav code.
//
// Chrome (header, search bar, filter chips, item-card style, bottom nav)
// matches the approved Figma file (rSY5pDmqY1jctcNOBg7gPC, node 37:285,
// "المحفوظات"). Figma's mockup shows sample "ملخصات"/"المفضلة" items, but
// this app only ever saves plain-text lecture transcripts today — no
// summary/OCR/favorite storage exists — so those two filters honestly show
// their own empty state instead of fabricating fake saved items. Figma's
// header also has no back button (it's a bottom-nav tab, not a pushed
// detail screen) and no delete-all/retention affordance; both real features
// are kept, tucked behind a small header icon button rather than silently
// dropped.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/a11y.dart';
import '/pages/settings/settings_screen.dart';
import '/theme.dart';
import '/services/app_prefs.dart';
import '/services/transcript_store.dart';

const double _kBottomNavHeight = 64.0;
const Color _kMutedCard = Color(0xFFE7E1D5);

enum _SavedFilter { all, texts, summaries, favorites }

class SavedTranscriptsPage extends StatefulWidget {
  const SavedTranscriptsPage({super.key});

  @override
  State<SavedTranscriptsPage> createState() => _SavedTranscriptsPageState();
}

class _SavedTranscriptsPageState extends State<SavedTranscriptsPage> {
  List<Transcript> _items = [];
  int _retentionDays = AppPrefs.defaultRetentionDays;
  bool _loading = true;
  _SavedFilter _filter = _SavedFilter.all;
  final _searchController = TextEditingController();
  String _query = '';

  static const _retentionOptions = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // "نصوص" and "الكل" both resolve to the same real data — plain-text
  // transcripts are the only saved content type this app has today.
  // "ملخصات"/"المفضلة" have no backing feature yet, so they filter to
  // nothing rather than showing invented sample data.
  List<Transcript> get _visibleItems {
    if (_filter == _SavedFilter.summaries || _filter == _SavedFilter.favorites) {
      return const [];
    }
    if (_query.isEmpty) return _items;
    return _items.where((t) => t.preview.contains(_query)).toList();
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} - ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _confirmDeleteAll() async {
    if (_items.isEmpty) return;
    final ok = await _confirm('saved.deleteAllConfirm'.tr());
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
        content: Text(message, textAlign: TextAlign.start, style: AppText.body()),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(), style: AppText.button(color: AppColors.mutedOnCream)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr(), style: AppText.button(color: Colors.white)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
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
              Text(_formatDate(t.createdAt), textAlign: TextAlign.start, style: AppText.label()),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    t.text,
                    textAlign: TextAlign.start,
                    style: AppText.custom(fontSize: 18.0, height: 1.7, color: AppColors.onCream),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              a11yButton(
                label: 'saved.copyText'.tr(),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.onNavy,
                    minimumSize: const Size.fromHeight(AppSpacing.minTap),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: t.text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('saved.textCopied'.tr(),
                            textAlign: TextAlign.start, style: AppText.body(color: AppColors.onNavy)),
                        backgroundColor: AppColors.navy,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text('saved.copy'.tr(), style: AppText.button(color: AppColors.onNavy)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text('saved.retentionTitle'.tr(), textAlign: TextAlign.start, style: AppText.title()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _retentionOptions
              .map((days) => RadioListTile<int>(
                    value: days,
                    groupValue: _retentionDays,
                    activeColor: AppColors.terracotta,
                    onChanged: (v) => Navigator.pop(ctx, v),
                    title: Text('saved.retentionDays'.tr(args: ['$days']),
                        textAlign: TextAlign.start, style: AppText.body()),
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

  void _showManageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.pill),
              ),
            ),
            ListTile(
              leading: Icon(Icons.auto_delete_outlined, color: AppColors.terracotta),
              title: Text('saved.autoDeleteLabel'.tr(args: ['$_retentionDays']),
                  textAlign: TextAlign.start, style: AppText.body()),
              subtitle: Text('saved.autoDeleteSub'.tr(),
                  textAlign: TextAlign.start, style: AppText.label()),
              onTap: () {
                Navigator.pop(ctx);
                _editRetention();
              },
            ),
            ListTile(
              enabled: _items.isNotEmpty,
              leading: Icon(Icons.delete_sweep_rounded,
                  color: _items.isEmpty ? AppColors.mutedOnCream : AppColors.error),
              title: Text('saved.deleteAllRow'.tr(),
                  textAlign: TextAlign.start,
                  style: AppText.body(
                      color: _items.isEmpty ? AppColors.mutedOnCream : AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAll();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          20.0, 8.0, 20.0, AppSpacing.xl + _kBottomNavHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _searchField(),
                          const SizedBox(height: 16.0),
                          _filterChips(),
                          const SizedBox(height: 16.0),
                          if (_visibleItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48.0),
                              child: Center(
                                child: Text(_emptyMessage(),
                                    style: AppText.body(color: AppColors.mutedOnCream)),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final t in _visibleItems) ...[
                                  _itemCard(t),
                                  const SizedBox(height: 4.0),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case _SavedFilter.summaries:
        return 'saved.emptySummaries'.tr();
      case _SavedFilter.favorites:
        return 'saved.emptyFavorites'.tr();
      default:
        return _query.isNotEmpty ? 'saved.emptyNoResults'.tr() : 'saved.emptyNone'.tr();
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 8.0),
      child: Row(
        children: [
          // Title is first so it renders at the row's start (right in RTL,
          // left in LTR) per Figma; the manage button (not in Figma) sits
          // at the opposite end rather than displacing the title.
          Text('saved.title'.tr(),
              textAlign: TextAlign.start,
              style: AppText.custom(
                  fontSize: 24, fontWeight: FontWeight.w800, height: 1.35, color: AppColors.onCream)),
          const Spacer(),
          a11yButton(
            label: 'saved.manage'.tr(),
            child: Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: EchoColors.shadow,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz_rounded, color: AppColors.mutedOnCream, size: 22),
                onPressed: _showManageSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: _kMutedCard,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.start,
        style: AppText.custom(
            fontSize: 14, fontWeight: FontWeight.w400, height: 1.0, color: AppColors.onCream),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14.8, vertical: 14.0),
          hintText: 'saved.searchHint'.tr(),
          hintStyle: AppText.custom(
              fontSize: 14, fontWeight: FontWeight.w400, height: 1.0, color: AppColors.mutedOnCream),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedOnCream, size: 19),
        ),
      ),
    );
  }

  Widget _filterChips() {
    Widget chip(_SavedFilter value, String label) {
      final active = _filter == value;
      return a11yButton(
        label: label,
        child: InkWell(
          onTap: () => setState(() => _filter = value),
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            height: 36.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.navy : AppColors.surface,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: active ? AppColors.navy : AppColors.border, width: 0.8),
            ),
            child: Text(label,
                style: AppText.custom(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: active ? AppColors.onNavy : AppColors.mutedOnCream)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          chip(_SavedFilter.all, 'saved.filterAll'.tr()),
          const SizedBox(width: 8.0),
          chip(_SavedFilter.texts, 'saved.filterTexts'.tr()),
          const SizedBox(width: 8.0),
          chip(_SavedFilter.summaries, 'saved.filterSummaries'.tr()),
          const SizedBox(width: 8.0),
          chip(_SavedFilter.favorites, 'saved.filterFavorites'.tr()),
        ],
      ),
    );
  }

  Widget _itemCard(Transcript t) {
    return a11yButton(
      label: '${t.preview}, ${_formatDate(t.createdAt)}',
      child: Dismissible(
        key: ValueKey(t.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirm('saved.deleteOneConfirm'.tr()),
        onDismissed: (_) async {
          await TranscriptStore.instance.delete(t.id);
          await _load();
        },
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: 20.0),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openViewer(t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.preview,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.custom(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: AppColors.onCream)),
                        const SizedBox(height: 2.0),
                        Text('saved.lectureTextDetail'.tr(args: [_formatDate(t.createdAt)]),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption()),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 42.0,
                    height: 42.0,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13.0),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.description_rounded,
                        size: 20.0, color: AppColors.mutedOnCream),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.8, vertical: 4.8),
                    decoration: BoxDecoration(
                      color: _kMutedCard,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Text('saved.tagText'.tr(),
                        style: AppText.caption(color: AppColors.mutedOnCream)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, AppSpacing.sm),
        child: Container(
          height: _kBottomNavHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F2),
            borderRadius: BorderRadius.circular(32.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.34),
                blurRadius: 17.0,
                offset: const Offset(0, 14.0),
              ),
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.09),
                blurRadius: 3.0,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: 'home.navHome'.tr(),
                active: false,
                onTap: () => Navigator.of(context).pop(),
              ),
              _navItem(
                icon: Icons.inventory_2_rounded,
                label: 'home.navArchive'.tr(),
                active: true,
                onTap: () {},
              ),
              _navItem(
                icon: Icons.person_rounded,
                label: 'home.navAccount'.tr(),
                active: false,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final iconColor = active ? AppColors.terracotta : AppColors.mutedOnCream;
    final labelColor = active ? AppColors.onCream : AppColors.mutedOnCream;
    return Expanded(
      child: a11yButton(
        label: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22.0, color: iconColor),
                const SizedBox(height: 2.0),
                Text(label,
                    style: AppText.caption(color: labelColor)
                        .copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
