import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/chat_repository.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  late Future<ChatInboxPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = ChatRepository.instance.loadFriendsInbox();
  }

  Future<void> _refresh() async {
    final future = ChatRepository.instance.loadFriendsInbox();
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
                activeTab: ChatPrimaryTab.friends,
                showSearch: true,
                onSearchTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatSearch);
                },
                onEditTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatSelection);
                },
                onDiscoverTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatDiscover);
                },
                onMessagesTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatMessages);
                },
                onFriendsTap: () {},
                body: FutureBuilder<ChatInboxPayload>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _RefreshableChatMessage(
                        onRefresh: _refresh,
                        child: const Text('تعذر تحميل المحادثات'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final threads = snapshot.data!.threads;
                    if (threads.isEmpty) {
                      return _RefreshableChatMessage(
                        onRefresh: _refresh,
                        child: const Text('لا توجد محادثات حالياً'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 6),
                        itemCount: threads.length,
                        itemBuilder: (context, index) {
                          final item = threads[index];
                          return ChatThreadRow(
                            title: item.title,
                            date: item.messageDateLabel,
                            preview: item.previewText,
                            avatarAsset: item.avatarAsset,
                            statusColor: _statusColor(item.statusColorHex),
                            readStyle: _readStyle(item.readStyle),
                            isPhotoMessage: item.isPhotoPreview,
                            onAvatarTap: () => _openThreadProfile(item),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.chatConversation,
                                arguments: item.id,
                              );
                            },
                          );
                        },
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
}

class _RefreshableChatMessage extends StatelessWidget {
  const _RefreshableChatMessage({required this.child, required this.onRefresh});

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

Color _statusColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16) ?? 0x34A853;
  return Color(0xFF000000 | value);
}

ChatReadStyle _readStyle(String value) {
  switch (value) {
    case 'single':
      return ChatReadStyle.single;
    case 'double':
      return ChatReadStyle.double;
    default:
      return ChatReadStyle.none;
  }
}
