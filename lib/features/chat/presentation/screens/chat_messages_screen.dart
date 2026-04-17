import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatMessagesScreen extends StatelessWidget {
  const ChatMessagesScreen({super.key});

  static const List<_MessageThreadData> _topItems = [
    _MessageThreadData(
      title: 'خدمه العملاء',
      preview: 'اي مشكله واجهتك يرجي تخبرني بتفاصيل',
      avatarType: _MessageAvatarType.support,
    ),
    _MessageThreadData(
      title: 'الاشعارات',
      preview: 'ممكن تعيطي هديه',
      avatarType: _MessageAvatarType.notification,
    ),
  ];

  static const List<_MessageThreadData> _bottomItems = [
    _MessageThreadData(
      title: 'محمد احمد',
      date: '11/16/19',
      preview: '',
      statusColor: Color(0xFFEA4335),
      readStyle: ChatReadStyle.single,
    ),
    _MessageThreadData(
      title: 'محمد احمد',
      date: '11/16/19',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      statusColor: Color(0xFF34A853),
      readStyle: ChatReadStyle.double,
    ),
    _MessageThreadData(
      title: 'محمد احمد',
      date: '11/16/19',
      preview: 'صورة',
      statusColor: Color(0xFF34A853),
      readStyle: ChatReadStyle.double,
      isPhotoMessage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ChatScreenFrame(
                activeTab: ChatPrimaryTab.messages,
                onEditTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatSelection);
                },
                onDiscoverTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                },
                onMessagesTap: () {},
                onFriendsTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatInbox);
                },
                body: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ..._topItems.map(
                      (item) => ChatThreadRow(
                        title: item.title,
                        preview: item.preview,
                        readStyle: ChatReadStyle.none,
                        showStatus: false,
                        avatarChild: _buildSpecialAvatar(item.avatarType),
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                        },
                      ),
                    ),
                    ..._bottomItems.map(
                      (item) => ChatThreadRow(
                        title: item.title,
                        date: item.date,
                        preview: item.preview,
                        statusColor: item.statusColor,
                        readStyle: item.readStyle,
                        isPhotoMessage: item.isPhotoMessage,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.chatConversation);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.chat,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSpecialAvatar(_MessageAvatarType type) {
    switch (type) {
      case _MessageAvatarType.defaultAvatar:
        return const Icon(Icons.person_rounded, color: Colors.white, size: 28);
      case _MessageAvatarType.support:
        return Image.asset(
          'assets/images/chat_support_icon.png',
          width: 30,
          height: 30,
          filterQuality: FilterQuality.high,
        );
      case _MessageAvatarType.notification:
        return Image.asset(
          'assets/images/chat_notification_icon.png',
          width: 30,
          height: 30,
          filterQuality: FilterQuality.high,
        );
    }
  }
}

class _MessageThreadData {
  const _MessageThreadData({
    required this.title,
    required this.preview,
    this.date,
    this.statusColor = const Color(0xFF34A853),
    this.readStyle = ChatReadStyle.none,
    this.isPhotoMessage = false,
    this.avatarType = _MessageAvatarType.defaultAvatar,
  });

  final String title;
  final String preview;
  final String? date;
  final Color statusColor;
  final ChatReadStyle readStyle;
  final bool isPhotoMessage;
  final _MessageAvatarType avatarType;
}

enum _MessageAvatarType { defaultAvatar, support, notification }
