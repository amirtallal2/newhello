import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({super.key});

  static const List<_FriendThreadData> _firstSection = [
    _FriendThreadData(
      name: 'محمد احمد',
      date: '11/16/19',
      preview: '',
      statusColor: Color(0xFFEA4335),
      readStyle: ChatReadStyle.single,
    ),
    _FriendThreadData(
      name: 'محمد احمد',
      date: '11/16/19',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      statusColor: Color(0xFF34A853),
      readStyle: ChatReadStyle.double,
    ),
    _FriendThreadData(
      name: 'محمد احمد',
      date: '11/16/19',
      preview: 'صورة',
      statusColor: Color(0xFF34A853),
      readStyle: ChatReadStyle.double,
      isPhotoMessage: true,
    ),
  ];

  static const List<_FriendThreadData> _secondSection = [
    _FriendThreadData(
      name: 'محمد احمد',
      date: '11/16/19',
      preview: '',
      statusColor: Color(0xFFEA4335),
      readStyle: ChatReadStyle.single,
    ),
    _FriendThreadData(
      name: 'محمد احمد',
      date: '11/16/19',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      statusColor: Color(0xFF34A853),
      readStyle: ChatReadStyle.double,
    ),
    _FriendThreadData(
      name: 'محمد احمد',
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
                activeTab: ChatPrimaryTab.friends,
                showSearch: true,
                onSearchTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatSearch);
                },
                onEditTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatSelection);
                },
                onDiscoverTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                },
                onMessagesTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatMessages);
                },
                onFriendsTap: () {},
                body: ListView(
                  padding: const EdgeInsets.only(top: 6),
                  children: [
                    ..._firstSection.map(
                      (item) => ChatThreadRow(
                        title: item.name,
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
                    const SizedBox(height: 1),
                    ..._secondSection.map(
                      (item) => ChatThreadRow(
                        title: item.name,
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
}

class _FriendThreadData {
  const _FriendThreadData({
    required this.name,
    required this.date,
    required this.preview,
    required this.statusColor,
    required this.readStyle,
    this.isPhotoMessage = false,
  });

  final String name;
  final String date;
  final String preview;
  final Color statusColor;
  final ChatReadStyle readStyle;
  final bool isPhotoMessage;
}
