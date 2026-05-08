import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/chat_repository.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatMessagesScreen extends StatefulWidget {
  const ChatMessagesScreen({super.key});

  @override
  State<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

Color _messagesStatusColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16) ?? 0x34A853;
  return Color(0xFF000000 | value);
}

ChatReadStyle _messagesReadStyle(String value) {
  switch (value) {
    case 'single':
      return ChatReadStyle.single;
    case 'double':
      return ChatReadStyle.double;
    default:
      return ChatReadStyle.none;
  }
}

class _ChatMessagesScreenState extends State<ChatMessagesScreen> {
  late Future<ChatMessagesPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = ChatRepository.instance.loadMessagesInbox();
  }

  Future<void> _refresh() async {
    final future = ChatRepository.instance.loadMessagesInbox();
    setState(() {
      _future = future;
    });
    await future;
  }

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
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatDiscover);
                },
                onMessagesTap: () {},
                onFriendsTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatInbox);
                },
                body: FutureBuilder<ChatMessagesPayload>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _RefreshableMessagesMessage(
                        onRefresh: _refresh,
                        child: const Text('تعذر تحميل الرسائل'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payload = snapshot.data!;
                    final hasThreads =
                        payload.systemThreads.isNotEmpty ||
                        payload.threads.isNotEmpty;
                    if (!hasThreads) {
                      return _RefreshableMessagesMessage(
                        onRefresh: _refresh,
                        child: const Text('لا توجد رسائل حالياً'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          ...payload.systemThreads.map(
                            (item) => ChatThreadRow(
                              title: item.title,
                              preview: item.previewText,
                              readStyle: ChatReadStyle.none,
                              showStatus: false,
                              avatarChild: _buildSystemAvatar(item.avatarAsset),
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.chatConversation,
                                  arguments: item.id,
                                );
                              },
                            ),
                          ),
                          ...payload.threads.map(
                            (item) => ChatThreadRow(
                              title: item.title,
                              date: item.messageDateLabel,
                              preview: item.previewText,
                              avatarAsset: item.avatarAsset,
                              statusColor: _messagesStatusColor(
                                item.statusColorHex,
                              ),
                              readStyle: _messagesReadStyle(item.readStyle),
                              isPhotoMessage: item.isPhotoPreview,
                              onAvatarTap: () => _openThreadProfile(item),
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.chatConversation,
                                  arguments: item.id,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  void _openThreadProfile(ChatThreadData item) {
    final userId = item.targetUserId;
    if (userId == null || userId < 1) {
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: userId,
        fallbackName: item.title,
        fallbackAvatarAsset: item.avatarAsset,
      ),
    );
  }

  static Widget _buildSystemAvatar(String assetPath) {
    return Image.asset(
      assetPath,
      width: 30,
      height: 30,
      filterQuality: FilterQuality.high,
    );
  }
}

class _RefreshableMessagesMessage extends StatelessWidget {
  const _RefreshableMessagesMessage({
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}
