// Notifications screen — new page, not previously part of the app. Matches
// the approved Figma file (rSY5pDmqY1jctcNOBg7gPC, node 37:543,
// "الإشعارات"). There is no notification backend anywhere in this app
// today (no push/poll service, no server-side notification model), so the
// four items are static sample content mirroring Figma's own mockup —
// but read/unread state and "mark all as read" are real, working local
// interaction (in-memory for this screen instance), not just decoration.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/a11y.dart';
import '/theme.dart';

class _NotificationItem {
  _NotificationItem({
    required this.icon,
    required this.titleKey,
    required this.timeKey,
    this.unread = true,
  });

  final IconData icon;
  // Translation keys, not resolved strings — resolved at build time via
  // .tr() so a locale change while this screen is on the stack still
  // reflows correctly instead of freezing at whatever language was active
  // when this list was constructed.
  final String titleKey;
  final String timeKey;
  bool unread;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _items = [
    _NotificationItem(
      icon: Icons.shield_rounded,
      titleKey: 'notifications.item1Title',
      timeKey: 'notifications.item1Time',
    ),
    _NotificationItem(
      icon: Icons.description_rounded,
      titleKey: 'notifications.item2Title',
      timeKey: 'notifications.item2Time',
    ),
    _NotificationItem(
      icon: Icons.assignment_rounded,
      titleKey: 'notifications.item3Title',
      timeKey: 'notifications.item3Time',
    ),
    _NotificationItem(
      icon: Icons.check_circle_rounded,
      titleKey: 'notifications.item4Title',
      timeKey: 'notifications.item4Time',
      unread: false,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.unread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: a11yButton(
                        label: 'notifications.markAllRead'.tr(),
                        child: InkWell(
                          onTap: _markAllRead,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Text('notifications.markAllRead'.tr(),
                                style: AppText.label(color: AppColors.terracotta)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    for (var i = 0; i < _items.length; i++) ...[
                      _itemCard(_items[i]),
                      if (i != _items.length - 1) const SizedBox(height: 6.0),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 12.0, 18.0, 14.8),
      child: Row(
        children: [
          a11yButton(
            label: 'common.back'.tr(),
            child: Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: EchoColors.shadow,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: appBackIcon(context, color: AppColors.mutedOnCream, size: 20.0),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('notifications.title'.tr(),
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.custom(
                    fontSize: 19, fontWeight: FontWeight.w800, height: 1.45, color: AppColors.onCream)),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(_NotificationItem item) {
    final title = item.titleKey.tr();
    final time = item.timeKey.tr();
    return a11yButton(
      label: item.unread
          ? '$title, $time, ${'notifications.unreadSuffix'.tr()}'
          : '$title, $time',
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => item.unread = false),
          child: Container(
            decoration: BoxDecoration(
              color: item.unread ? const Color(0xFFE7E1D5) : Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 13.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, size: 19.0, color: AppColors.mutedOnCream),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.custom(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.65,
                              color: AppColors.onCream)),
                      const SizedBox(height: 2.0),
                      Text(time, textAlign: TextAlign.start, style: AppText.caption()),
                    ],
                  ),
                ),
                if (item.unread) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: 7.0),
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
