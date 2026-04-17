import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  bool _showFriendsOnly = false;

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFF9DB2CE);
  static const Color _tabInactive = Color(0xFFB4D1EF);
  static const Color _cardBackground = Color(0xFFF3F3F3);
  static const Color _actionBackground = Color(0xFFB4D1EF);

  static const List<_PostData> _posts = [
    _PostData(
      author: 'اسماء فتحي',
      relativeTime: '12 hours ago',
      date: '10/25/2024',
      content:
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔',
      isFriendPost: true,
    ),
    _PostData(
      author: 'اسماء فتحي',
      relativeTime: '12 hours ago',
      date: '10/25/2024',
      content:
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔',
      isFriendPost: true,
    ),
    _PostData(
      author: 'اسماء فتحي',
      relativeTime: '12 hours ago',
      date: '10/25/2024',
      content:
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔',
      isFriendPost: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayedPosts = _showFriendsOnly
        ? _posts.where((post) => post.isFriendPost).toList()
        : _posts;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 60, 18, 0),
                      child: Column(
                        children: [
                          _HeaderRow(
                            showFriendsOnly: _showFriendsOnly,
                            onShowAllTap: () {
                              setState(() {
                                _showFriendsOnly = false;
                              });
                            },
                            onShowFriendsTap: () {
                              setState(() {
                                _showFriendsOnly = true;
                              });
                            },
                            onNotificationTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.bootstrap,
                              );
                            },
                          ),
                          const SizedBox(height: 43),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: displayedPosts.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (context, index) {
                                final post = displayedPosts[index];
                                return _PostCard(
                                  post: post,
                                  showUnfollowState: _showFriendsOnly,
                                  onFollowTap: () {},
                                  onReportTap: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.bootstrap,
                                    );
                                  },
                                  onPrimaryActionTap: () {},
                                  onSecondaryActionTap: () {},
                                  onTertiaryActionTap: () {},
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 16,
                    bottom: 30,
                    child: Semantics(
                      label: 'post-compose-button',
                      button: true,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.postCreate,
                          );
                        },
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: _lightBlue,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/post_compose_icon.png',
                            width: 30,
                            height: 30,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.post,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.showFriendsOnly,
    required this.onShowAllTap,
    required this.onShowFriendsTap,
    required this.onNotificationTap,
  });

  final bool showFriendsOnly;
  final VoidCallback onShowAllTap;
  final VoidCallback onShowFriendsTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: 'post-notification-button',
          button: true,
          child: InkWell(
            onTap: onNotificationTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: _PostScreenState._primaryBlue,
                      size: 18,
                    ),
                  ),
                  PositionedDirectional(
                    top: -2,
                    end: -2,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: _PostScreenState._primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        _TopTab(
          key: const ValueKey('post-tab-all'),
          label: 'الجميع',
          isActive: !showFriendsOnly,
          onTap: onShowAllTap,
        ),
        const SizedBox(width: 40),
        _TopTab(
          key: const ValueKey('post-tab-friends'),
          label: 'الاصدقاء',
          isActive: showFriendsOnly,
          onTap: onShowFriendsTap,
        ),
      ],
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? _PostScreenState._primaryBlue
                  : _PostScreenState._tabInactive,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: label == 'الاصدقاء' ? 56 : 44,
            height: 1,
            decoration: BoxDecoration(
              color: isActive
                  ? _PostScreenState._primaryBlue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.showUnfollowState,
    required this.onFollowTap,
    required this.onReportTap,
    required this.onPrimaryActionTap,
    required this.onSecondaryActionTap,
    required this.onTertiaryActionTap,
  });

  final _PostData post;
  final bool showUnfollowState;
  final VoidCallback onFollowTap;
  final VoidCallback onReportTap;
  final VoidCallback onPrimaryActionTap;
  final VoidCallback onSecondaryActionTap;
  final VoidCallback onTertiaryActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      padding: const EdgeInsets.fromLTRB(17, 20, 17, 9),
      decoration: BoxDecoration(
        color: _PostScreenState._cardBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onFollowTap,
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      width: 57,
                      height: 20,
                      decoration: BoxDecoration(
                        color: showUnfollowState
                            ? _PostScreenState._lightBlue
                            : _PostScreenState._primaryBlue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        showUnfollowState ? 'الغاء المتابعة' : 'متابعة',
                        style: TextStyle(
                          color: showUnfollowState
                              ? _PostScreenState._primaryBlue
                              : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  InkWell(
                    onTap: onReportTap,
                    child: const Text(
                      'ابلاغ عن مشكلة',
                      style: TextStyle(
                        color: _PostScreenState._lightBlue,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    post.author,
                    style: const TextStyle(
                      color: _PostScreenState._primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.date,
                        style: const TextStyle(
                          color: _PostScreenState._lightBlue,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        post.relativeTime,
                        style: const TextStyle(
                          color: _PostScreenState._lightBlue,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/post_author_avatar.png'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 128,
                child: Text(
                  post.content,
                  textAlign: TextAlign.right,
                  maxLines: 6,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    height: 1.75,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PostActionButton(
                  iconAsset: 'assets/images/post_action_icon_1.png',
                  onTap: onPrimaryActionTap,
                ),
                const SizedBox(width: 5),
                _PostActionButton(
                  iconAsset: 'assets/images/post_action_icon_2.png',
                  onTap: onSecondaryActionTap,
                  badgeText: '1',
                ),
                const SizedBox(width: 5),
                _PostActionButton(
                  iconAsset: 'assets/images/post_action_icon_3.png',
                  onTap: onTertiaryActionTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.iconAsset,
    required this.onTap,
    this.badgeText,
  });

  final String iconAsset;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: _PostScreenState._actionBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        if (badgeText != null)
          PositionedDirectional(
            end: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _PostScreenState._primaryBlue,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PostData {
  const _PostData({
    required this.author,
    required this.relativeTime,
    required this.date,
    required this.content,
    required this.isFriendPost,
  });

  final String author;
  final String relativeTime;
  final String date;
  final String content;
  final bool isFriendPost;
}
