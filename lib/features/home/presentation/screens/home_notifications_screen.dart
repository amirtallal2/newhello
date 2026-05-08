import 'package:flutter/material.dart';

import '../../../post/data/post_repository.dart';
import '../../data/live_repository.dart';
import '../widgets/main_bottom_navigation.dart';

class HomeNotificationsScreen extends StatefulWidget {
  const HomeNotificationsScreen({super.key});

  @override
  State<HomeNotificationsScreen> createState() =>
      _HomeNotificationsScreenState();
}

class _HomeNotificationsScreenState extends State<HomeNotificationsScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _titleColor = Color(0xFF1A2155);

  late Future<List<_HomeNotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadNotifications();
  }

  Future<List<_HomeNotificationItem>> _loadNotifications() async {
    final postPayload = await PostRepository.instance.loadNotifications();
    final liveNotifications = await LiveRepository.instance.listNotifications();

    final items = <_HomeNotificationItem>[
      ...postPayload.notifications.map(_HomeNotificationItem.fromPost),
      ...liveNotifications.map(_HomeNotificationItem.fromLive),
    ];

    items.sort((left, right) => left.sortKey.compareTo(right.sortKey));
    await PostRepository.instance.markNotificationsRead();
    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadNotifications();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: _primaryBlue,
                  onRefresh: _refresh,
                  child: FutureBuilder<List<_HomeNotificationItem>>(
                    future: _future,
                    builder: (context, snapshot) {
                      final items =
                          snapshot.data ?? const <_HomeNotificationItem>[];
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 52, 18, 24),
                        children: [
                          _NotificationHeader(
                            onBackTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 37),
                          if (snapshot.connectionState != ConnectionState.done)
                            const Padding(
                              padding: EdgeInsets.only(top: 120),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primaryBlue,
                                ),
                              ),
                            )
                          else if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 120),
                              child: Center(
                                child: Text(
                                  'لا توجد إشعارات الآن',
                                  style: TextStyle(
                                    color: _primaryBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _NotificationListItem(item: item),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const MainBottomNavigation(
                currentTab: MainBottomNavigationTab.home,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'home-notifications-back',
            child: InkWell(
              onTap: onBackTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 37,
                decoration: const BoxDecoration(
                  color: _HomeNotificationsScreenState._lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: _HomeNotificationsScreenState._primaryBlue,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'الاشعارات الخاصة بك',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _HomeNotificationsScreenState._primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationListItem extends StatelessWidget {
  const _NotificationListItem({required this.item});

  final _HomeNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 41),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              item.timeLabel,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: _HomeNotificationsScreenState._titleColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeNotificationsScreenState._titleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.highlight,
                        style: const TextStyle(
                          color: _HomeNotificationsScreenState._primaryBlue,
                        ),
                      ),
                      TextSpan(text: item.bodyTail),
                    ],
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeNotificationsScreenState._titleColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 19,
            height: 18,
            decoration: BoxDecoration(
              color: _HomeNotificationsScreenState._primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(item.icon, color: Colors.white, size: 11),
          ),
        ],
      ),
    );
  }
}

final class _HomeNotificationItem {
  const _HomeNotificationItem({
    required this.id,
    required this.title,
    required this.highlight,
    required this.bodyTail,
    required this.timeLabel,
    required this.icon,
    required this.sortKey,
  });

  final int id;
  final String title;
  final String highlight;
  final String bodyTail;
  final String timeLabel;
  final IconData icon;
  final int sortKey;

  factory _HomeNotificationItem.fromPost(PostNotificationData data) {
    final title = switch (data.notificationType) {
      'comment' => 'تعليق جديد',
      'like' => 'إعجاب جديد',
      'share' => 'مشاركة جديدة',
      _ => 'إشعار منشور',
    };

    return _HomeNotificationItem(
      id: data.id,
      title: title,
      highlight: data.message,
      bodyTail: data.isRead ? ' تم الاطلاع عليه.' : ' لديك تحديث جديد.',
      timeLabel: _normalizeTimeLabel(data.createdAtLabel),
      icon: data.notificationType == 'like'
          ? Icons.favorite_rounded
          : Icons.notifications_rounded,
      sortKey: data.id,
    );
  }

  factory _HomeNotificationItem.fromLive(LiveNotificationData data) {
    return _HomeNotificationItem(
      id: data.id,
      title: data.title.isEmpty ? 'إشعار لايف' : data.title,
      highlight: data.message,
      bodyTail: data.roomTitle.isEmpty
          ? ' تابع آخر تحديثات التطبيق.'
          : ' ${data.roomTitle}',
      timeLabel: _normalizeTimeLabel(data.createdAtLabel),
      icon: Icons.campaign_rounded,
      sortKey: 100000 + data.id,
    );
  }

  static String _normalizeTimeLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'just now') {
      return 'الآن';
    }
    if (normalized.contains('min')) {
      final value = RegExp(r'\d+').firstMatch(normalized)?.group(0) ?? '';
      return value.isEmpty ? 'دقائق' : '$value دقائق';
    }
    if (normalized.contains('hour')) {
      final value = RegExp(r'\d+').firstMatch(normalized)?.group(0) ?? '';
      return value.isEmpty ? 'ساعات' : '$value ساعات';
    }
    if (normalized.contains('day')) {
      final value = RegExp(r'\d+').firstMatch(normalized)?.group(0) ?? '';
      return value.isEmpty ? 'أيام' : '$value أيام';
    }
    return label;
  }
}
