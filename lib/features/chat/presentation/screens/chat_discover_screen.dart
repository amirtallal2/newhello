import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../social/data/social_repository.dart';
import '../../data/chat_repository.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatDiscoverScreen extends StatefulWidget {
  const ChatDiscoverScreen({super.key});

  @override
  State<ChatDiscoverScreen> createState() => _ChatDiscoverScreenState();
}

class _ChatDiscoverScreenState extends State<ChatDiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<SocialUserData>> _future;
  int? _openingUserId;

  @override
  void initState() {
    super.initState();
    _future = SocialRepository.instance.searchUsers(query: '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _future = SocialRepository.instance.searchUsers(query: query);
    });
  }

  Future<void> _refresh() async {
    final future = SocialRepository.instance.searchUsers(
      query: _searchController.text,
    );
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openChat(SocialUserData user) async {
    if (_openingUserId != null) {
      return;
    }

    setState(() {
      _openingUserId = user.id;
    });

    try {
      final conversation = await ChatRepository.instance.openDirectThread(
        userId: user.id,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.chatConversation,
        arguments: conversation.thread.id,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _openingUserId = null;
        });
      }
    }
  }

  void _openProfile(SocialUserData user) {
    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: user.id,
        fallbackName: user.name,
        fallbackAvatarAsset: user.avatarAsset,
      ),
    );
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
                activeTab: ChatPrimaryTab.discover,
                onEditTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatSelection);
                },
                onDiscoverTap: () {},
                onMessagesTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatMessages);
                },
                onFriendsTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatInbox);
                },
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: _DiscoverSearchField(
                        controller: _searchController,
                        onChanged: _search,
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<SocialUserData>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _DiscoverRefreshableMessage(
                              onRefresh: _refresh,
                              child: const Text('تعذر تحميل المستخدمين'),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final users = snapshot.data!;
                          if (users.isEmpty) {
                            return _DiscoverRefreshableMessage(
                              onRefresh: _refresh,
                              child: const Text('لا توجد نتائج حالياً'),
                            );
                          }

                          return RefreshIndicator(
                            color: ChatScreenPalette.primaryBlue,
                            onRefresh: _refresh,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: users.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return _DiscoverUserCard(
                                  user: user,
                                  isOpening: _openingUserId == user.id,
                                  onChatTap: () => _openChat(user),
                                  onProfileTap: () => _openProfile(user),
                                );
                              },
                            ),
                          );
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

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        key: const ValueKey('chat-discover-search-field'),
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'ابحث عن مستخدم لبدء محادثة',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ChatScreenPalette.primaryBlue,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _DiscoverUserCard extends StatelessWidget {
  const _DiscoverUserCard({
    required this.user,
    required this.isOpening,
    required this.onChatTap,
    required this.onProfileTap,
  });

  final SocialUserData user;
  final bool isOpening;
  final VoidCallback onChatTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 54,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ResolvedImage(path: user.avatarAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onProfileTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${user.subtitle} · ${user.country}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6F7C8F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: isOpening ? null : onChatTap,
              icon: isOpening
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_rounded, size: 16),
              label: Text(isOpening ? 'فتح...' : 'مراسلة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatScreenPalette.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverRefreshableMessage extends StatelessWidget {
  const _DiscoverRefreshableMessage({
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ChatScreenPalette.primaryBlue,
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
