import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/post_repository.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'post_create_screen.dart';

enum _PostMenuAction { edit, delete, report, like, comments, share }

enum _PostCommentAction { edit, delete, report }

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFF9DB2CE);
  static const Color _tabInactive = Color(0xFFB4D1EF);
  static const Color _cardBackground = Color(0xFFF3F3F3);
  static const Color _actionBackground = Color(0xFFB4D1EF);

  final PostRepository _repository = PostRepository.instance;

  bool _showFriendsOnly = false;
  bool _isLoading = true;
  String? _errorMessage;
  int _notificationCount = 0;
  List<PostItemData> _posts = const <PostItemData>[];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

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
                    child: ResponsiveContent(
                      maxWidth: 460,
                      padding: EdgeInsets.fromLTRB(
                        metrics.pageHorizontalPadding(),
                        metrics.spacing(60, min: 42, max: 64),
                        metrics.pageHorizontalPadding(),
                        0,
                      ),
                      child: Column(
                        children: [
                          _HeaderRow(
                            notificationCount: _notificationCount,
                            showFriendsOnly: _showFriendsOnly,
                            onShowAllTap: () => _switchTab(false),
                            onShowFriendsTap: () => _switchTab(true),
                            onNotificationTap: _openNotifications,
                          ),
                          SizedBox(
                            height: metrics.spacing(43, min: 22, max: 43),
                          ),
                          Expanded(child: _buildBody()),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: metrics.pageHorizontalPadding(
                      compact: 12,
                      regular: 16,
                    ),
                    bottom: metrics.spacing(30, min: 18, max: 30),
                    child: Semantics(
                      label: 'post-compose-button',
                      button: true,
                      child: InkWell(
                        onTap: _openComposer,
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: metrics.spacing(38, min: 34, max: 42),
                          height: metrics.spacing(38, min: 34, max: 42),
                          decoration: const BoxDecoration(
                            color: _lightBlue,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/post_compose_icon.png',
                            width: metrics.spacing(30, min: 26, max: 34),
                            height: metrics.spacing(30, min: 26, max: 34),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (_errorMessage != null) {
      return _RefreshableBody(
        onRefresh: _loadFeed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return _RefreshableBody(
        onRefresh: _loadFeed,
        child: const Text(
          'لا يوجد منشورات حاليا',
          style: TextStyle(
            color: _primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _PostCard(
            post: post,
            onFollowTap: () => _toggleFollow(post),
            onLongPressAction: () => _openPostActions(post),
            onAuthorTap: () => _openAuthorProfile(post),
            onPrimaryActionTap: () => _toggleLike(post),
            onSecondaryActionTap: () => _openComments(post),
            onTertiaryActionTap: () => _sharePost(post),
          );
        },
      ),
    );
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feed = await _repository.loadFeed(friendsOnly: _showFriendsOnly);
      if (!mounted) {
        return;
      }

      setState(() {
        _notificationCount = feed.notificationCount;
        _posts = feed.posts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _switchTab(bool friendsOnly) {
    if (_showFriendsOnly == friendsOnly) {
      return;
    }

    setState(() {
      _showFriendsOnly = friendsOnly;
    });
    _loadFeed();
  }

  Future<void> _openComposer() async {
    final created = await Navigator.of(context).pushNamed(AppRoutes.postCreate);
    if (!mounted) {
      return;
    }

    if (created is PostItemData) {
      setState(() {
        _posts = [created, ..._posts.where((item) => item.id != created.id)];
      });
      return;
    }

    if (created == true) {
      await _loadFeed();
    }
  }

  Future<void> _openAuthorProfile(PostItemData post) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: post.authorUserId,
        fallbackName: post.authorName,
        fallbackAvatarAsset: post.authorAvatarAsset,
        fallbackHandle: post.authorKey,
        isCurrentUser: post.canEdit || !post.canFollow,
      ),
    );
  }

  Future<void> _toggleFollow(PostItemData post) async {
    if (!post.canFollow) {
      return;
    }

    try {
      final result = await _repository.toggleFollow(postId: post.id);
      if (!mounted) {
        return;
      }

      if (_showFriendsOnly && !result.isFollowed) {
        _loadFeed();
        return;
      }

      setState(() {
        _posts = _posts
            .map(
              (item) => item.authorKey == result.authorKey
                  ? item.copyWith(
                      isFollowed: result.isFollowed,
                      canFollow: result.canFollow,
                    )
                  : item,
            )
            .toList();
      });
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _reportPost(PostItemData post) async {
    try {
      final reasons = await _repository.loadReportReasons();
      if (!mounted) {
        return;
      }

      final selectedReason = await showModalBottomSheet<PostReportReasonData>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _PostReportReasonsSheet(
            reasons: reasons.isEmpty
                ? const <PostReportReasonData>[
                    PostReportReasonData(
                      id: 0,
                      reasonKey: 'other',
                      label: 'سبب آخر',
                      description: 'إرسال بلاغ عام لمراجعة الأدمن.',
                    ),
                  ]
                : reasons,
          );
        },
      );

      if (selectedReason == null) {
        return;
      }

      await _repository.reportPost(
        postId: post.id,
        reasonKey: selectedReason.reasonKey,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ بنجاح.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _editPost(PostItemData post) async {
    if (!post.canEdit) {
      return;
    }

    final result = await Navigator.of(context).pushNamed(
      AppRoutes.postCreate,
      arguments: PostCreateScreenArgs(editPost: post),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result is PostItemData) {
      _replacePost(result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تعديل المنشور.')));
    }
  }

  Future<void> _deletePost(PostItemData post) async {
    if (!post.canDelete) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف المنشور'),
            content: const Text(
              'سيتم إخفاء المنشور من التطبيق ولن يظهر للمستخدمين. هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB45A5A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deletePost(postId: post.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = _posts.where((item) => item.id != post.id).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المنشور.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _openPostActions(PostItemData post) async {
    final action = await showModalBottomSheet<_PostMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PostActionsSheet(post: post);
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _PostMenuAction.edit:
        await _editPost(post);
      case _PostMenuAction.delete:
        await _deletePost(post);
      case _PostMenuAction.report:
        await _reportPost(post);
      case _PostMenuAction.like:
        await _toggleLike(post);
      case _PostMenuAction.comments:
        await _openComments(post);
      case _PostMenuAction.share:
        await _sharePost(post);
    }
  }

  Future<void> _toggleLike(PostItemData post) async {
    try {
      final updated = await _repository.toggleLike(postId: post.id);
      if (!mounted) {
        return;
      }
      _replacePost(updated);
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _sharePost(PostItemData post) async {
    try {
      final sharedPost = await _repository.sharePost(postId: post.id);
      if (!mounted) {
        return;
      }
      setState(() {
        final existingIndex = _posts.indexWhere(
          (item) => item.id == sharedPost.id,
        );
        if (existingIndex == -1) {
          _posts = [sharedPost, ..._posts];
        } else {
          _posts = _posts
              .map((item) => item.id == sharedPost.id ? sharedPost : item)
              .toList();
        }

        _posts = _posts
            .map(
              (item) => item.id == post.id
                  ? item.copyWith(shareCount: item.shareCount + 1)
                  : item,
            )
            .toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت مشاركة المنشور.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _openComments(PostItemData post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PostCommentsSheet(
          postId: post.id,
          repository: _repository,
          onCommentCountChanged: (count) {
            if (!mounted) {
              return;
            }
            setState(() {
              _posts = _posts
                  .map(
                    (item) => item.id == post.id
                        ? item.copyWith(commentCount: count)
                        : item,
                  )
                  .toList();
            });
          },
        );
      },
    );
  }

  Future<void> _openNotifications() async {
    try {
      final notifications = await _repository.loadNotifications();
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _PostNotificationsSheet(payload: notifications);
        },
      );

      final unreadCount = await _repository.markNotificationsRead();
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationCount = unreadCount;
      });
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _replacePost(PostItemData updated) {
    setState(() {
      _posts = _posts
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RefreshableBody extends StatelessWidget {
  const _RefreshableBody({required this.child, required this.onRefresh});

  final Widget child;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _PostScreenState._primaryBlue,
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.52,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.notificationCount,
    required this.showFriendsOnly,
    required this.onShowAllTap,
    required this.onShowFriendsTap,
    required this.onNotificationTap,
  });

  final int notificationCount;
  final bool showFriendsOnly;
  final VoidCallback onShowAllTap;
  final VoidCallback onShowFriendsTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Row(
      children: [
        Semantics(
          label: 'post-notification-button',
          button: true,
          child: InkWell(
            onTap: onNotificationTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: metrics.spacing(32, min: 30, max: 36),
              height: metrics.spacing(32, min: 30, max: 36),
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
                  if (notificationCount > 0)
                    PositionedDirectional(
                      top: -2,
                      end: -2,
                      child: Container(
                        width: metrics.spacing(15, min: 13, max: 16),
                        height: metrics.spacing(15, min: 13, max: 16),
                        decoration: const BoxDecoration(
                          color: _PostScreenState._primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          notificationCount > 9
                              ? '9+'
                              : notificationCount.toString(),
                          style: const TextStyle(
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
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: metrics.spacing(18, min: 12, max: 28),
              runSpacing: metrics.spacing(6, min: 4, max: 8),
              children: [
                _TopTab(
                  key: const ValueKey('post-tab-all'),
                  label: 'الجميع',
                  isActive: !showFriendsOnly,
                  onTap: onShowAllTap,
                ),
                _TopTab(
                  key: const ValueKey('post-tab-friends'),
                  label: 'الاصدقاء',
                  isActive: showFriendsOnly,
                  onTap: onShowFriendsTap,
                ),
              ],
            ),
          ),
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
    final metrics = ResponsiveMetrics.of(context);

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
              fontSize: metrics.font(15, min: 13, max: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: metrics.spacing(5, min: 4, max: 6)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: metrics.spacing(
              label == 'الاصدقاء' ? 56 : 44,
              min: 34,
              max: 56,
            ),
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
    required this.onFollowTap,
    required this.onLongPressAction,
    required this.onAuthorTap,
    required this.onPrimaryActionTap,
    required this.onSecondaryActionTap,
    required this.onTertiaryActionTap,
  });

  final PostItemData post;
  final VoidCallback onFollowTap;
  final VoidCallback onLongPressAction;
  final VoidCallback onAuthorTap;
  final VoidCallback onPrimaryActionTap;
  final VoidCallback onSecondaryActionTap;
  final VoidCallback onTertiaryActionTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final followLabel = post.isFollowed ? 'الغاء المتابعة' : 'متابعة';
    final followBackground = post.isFollowed
        ? _PostScreenState._lightBlue
        : _PostScreenState._primaryBlue;
    final followForeground = post.isFollowed
        ? _PostScreenState._primaryBlue
        : Colors.white;
    final displayBody = post.isShared
        ? (post.sharedBodyText?.trim().isNotEmpty == true
              ? post.sharedBodyText!
              : post.bodyText)
        : post.bodyText;
    final displayImage = post.isShared
        ? (post.sharedImagePath ?? post.imagePath)
        : post.imagePath;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPressAction,
      child: Container(
        constraints: BoxConstraints(
          minHeight: metrics.spacing(232, min: 218, max: 280),
        ),
        padding: EdgeInsets.fromLTRB(
          metrics.spacing(16, min: 14, max: 20),
          metrics.spacing(16, min: 14, max: 20),
          metrics.spacing(16, min: 14, max: 20),
          metrics.spacing(12, min: 10, max: 14),
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.isShared) ...[
              _SharedPostBanner(post: post),
              SizedBox(height: metrics.spacing(12, min: 10, max: 14)),
            ],
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onAuthorTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: metrics.spacing(20, min: 18, max: 22),
                            backgroundImage: resolvedImageProvider(
                              post.authorAvatarAsset,
                            ),
                          ),
                          SizedBox(width: metrics.spacing(10, min: 8, max: 10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  post.authorName,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _PostScreenState._primaryBlue,
                                    fontSize: metrics.font(
                                      14,
                                      min: 13,
                                      max: 16,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(
                                  height: metrics.spacing(5, min: 4, max: 6),
                                ),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: metrics.spacing(10, min: 6, max: 10),
                                  runSpacing: metrics.spacing(
                                    2,
                                    min: 2,
                                    max: 4,
                                  ),
                                  children: [
                                    Text(
                                      post.dateLabel,
                                      style: TextStyle(
                                        color: _PostScreenState._lightBlue,
                                        fontSize: metrics.font(
                                          10,
                                          min: 9,
                                          max: 11,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      post.relativeTime,
                                      style: TextStyle(
                                        color: _PostScreenState._lightBlue,
                                        fontSize: metrics.font(
                                          10,
                                          min: 9,
                                          max: 11,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (post.canFollow) ...[
                  SizedBox(width: metrics.spacing(10, min: 8, max: 10)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.spacing(92, min: 78, max: 106),
                    ),
                    child: InkWell(
                      onTap: onFollowTap,
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        width: double.infinity,
                        height: metrics.spacing(24, min: 22, max: 28),
                        decoration: BoxDecoration(
                          color: followBackground,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          followLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: followForeground,
                            fontSize: metrics.font(10, min: 9, max: 11),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: metrics.spacing(16, min: 12, max: 18)),
            if (displayBody.trim().isNotEmpty)
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  displayBody,
                  textAlign: TextAlign.right,
                  maxLines: displayImage == null ? 8 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: metrics.font(13, min: 12, max: 15),
                    fontWeight: FontWeight.w600,
                    height: 1.65,
                  ),
                ),
              ),
            if (displayImage != null && displayImage.trim().isNotEmpty) ...[
              SizedBox(height: metrics.spacing(12, min: 10, max: 14)),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: metrics.spacing(190, min: 160, max: 260),
                  color: Colors.white,
                  child: ResolvedImage(path: displayImage, fit: BoxFit.cover),
                ),
              ),
            ],
            SizedBox(height: metrics.spacing(14, min: 12, max: 16)),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PostActionButton(
                    key: ValueKey(
                      'post-like-${post.id}-${post.isLiked ? 'on' : 'off'}',
                    ),
                    iconAsset: 'assets/images/post_action_icon_1.png',
                    onTap: onPrimaryActionTap,
                    isActive: post.isLiked,
                    semanticLabel: post.isLiked ? 'unlike-post' : 'like-post',
                    badgeText: post.likeCount > 0
                        ? post.likeCount.toString()
                        : null,
                  ),
                  SizedBox(width: metrics.spacing(5, min: 4, max: 6)),
                  _PostActionButton(
                    key: ValueKey('post-comment-${post.id}'),
                    iconAsset: 'assets/images/post_action_icon_2.png',
                    onTap: onSecondaryActionTap,
                    semanticLabel: 'comment-post',
                    badgeText: post.commentCount > 0
                        ? post.commentCount.toString()
                        : null,
                  ),
                  SizedBox(width: metrics.spacing(5, min: 4, max: 6)),
                  _PostActionButton(
                    key: ValueKey('post-share-${post.id}'),
                    iconAsset: 'assets/images/post_action_icon_3.png',
                    onTap: onTertiaryActionTap,
                    semanticLabel: 'share-post',
                    badgeText: post.shareCount > 0
                        ? post.shareCount.toString()
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedPostBanner extends StatelessWidget {
  const _SharedPostBanner({required this.post});

  final PostItemData post;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final originalAuthor = post.sharedAuthorName?.trim().isNotEmpty == true
        ? post.sharedAuthorName!
        : 'منشور';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(12, min: 10, max: 14),
        vertical: metrics.spacing(9, min: 8, max: 10),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E6F2)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(
            Icons.repeat_rounded,
            color: _PostScreenState._primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${post.authorName} شارك منشور $originalAuthor',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _PostScreenState._primaryBlue,
                fontSize: metrics.font(11, min: 10, max: 13),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActionsSheet extends StatelessWidget {
  const _PostActionsSheet({required this.post});

  final PostItemData post;

  @override
  Widget build(BuildContext context) {
    final isOwnPost = post.canEdit || post.canDelete;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E6F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'اختيارات المنشور',
                  style: TextStyle(
                    color: _PostScreenState._primaryBlue,
                    fontSize: ResponsiveMetrics.of(
                      context,
                    ).font(16, min: 15, max: 17),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _PostMenuTile(
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  title: post.isLiked ? 'إلغاء اللايك' : 'لايك',
                  subtitle: post.likeCount > 0
                      ? '${post.likeCount} إعجاب'
                      : 'سجل إعجابك بالمنشور',
                  onTap: () => Navigator.of(context).pop(_PostMenuAction.like),
                ),
                _PostMenuTile(
                  icon: Icons.mode_comment_outlined,
                  title: 'التعليقات',
                  subtitle: post.commentCount > 0
                      ? '${post.commentCount} تعليق'
                      : 'افتح التعليقات واكتب تعليقك',
                  onTap: () =>
                      Navigator.of(context).pop(_PostMenuAction.comments),
                ),
                _PostMenuTile(
                  icon: Icons.ios_share_rounded,
                  title: 'مشاركة',
                  subtitle: post.shareCount > 0
                      ? '${post.shareCount} مشاركة'
                      : 'مشاركة المنشور وتحديث عداد المشاركات',
                  onTap: () => Navigator.of(context).pop(_PostMenuAction.share),
                ),
                if (post.canEdit)
                  _PostMenuTile(
                    icon: Icons.edit_note_rounded,
                    title: 'تعديل المنشور',
                    subtitle: 'تعديل النص المنشور',
                    onTap: () =>
                        Navigator.of(context).pop(_PostMenuAction.edit),
                  ),
                if (post.canDelete)
                  _PostMenuTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'حذف المنشور',
                    subtitle: 'إخفاء المنشور من التطبيق',
                    danger: true,
                    onTap: () =>
                        Navigator.of(context).pop(_PostMenuAction.delete),
                  ),
                if (!isOwnPost)
                  _PostMenuTile(
                    icon: Icons.outlined_flag_rounded,
                    title: 'إبلاغ عن مشكلة',
                    subtitle: 'إرسال البلاغ للإدارة مع اختيار السبب',
                    danger: true,
                    onTap: () =>
                        Navigator.of(context).pop(_PostMenuAction.report),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostMenuTile extends StatelessWidget {
  const _PostMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xFFB45A5A)
        : _PostScreenState._primaryBlue;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF6F7C8F),
          fontSize: 11,
          height: 1.35,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    super.key,
    required this.iconAsset,
    required this.onTap,
    required this.semanticLabel,
    this.isActive = false,
    this.badgeText,
  });

  final String iconAsset;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool isActive;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: metrics.spacing(28, min: 26, max: 30),
              height: metrics.spacing(28, min: 26, max: 30),
              decoration: BoxDecoration(
                color: _PostScreenState._actionBackground,
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(
                        color: _PostScreenState._primaryBlue,
                        width: 1.5,
                      )
                    : null,
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x33285F98),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                iconAsset,
                width: metrics.spacing(14, min: 12, max: 15),
                height: metrics.spacing(14, min: 12, max: 15),
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          if (badgeText != null)
            PositionedDirectional(
              top: -4,
              start: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 11),
                height: 11,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1F4C78)
                      : _PostScreenState._primaryBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({
    required this.postId,
    required this.repository,
    required this.onCommentCountChanged,
  });

  final int postId;
  final PostRepository repository;
  final ValueChanged<int> onCommentCountChanged;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  static const Color _primaryBlue = Color(0xFF285F98);

  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<PostCommentData> _comments = const <PostCommentData>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: EdgeInsets.only(
        top: 16,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E6F2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'التعليقات',
              style: TextStyle(
                color: _primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryBlue),
                    )
                  : _comments.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد تعليقات حاليا',
                        style: TextStyle(
                          color: _primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _comments.length,
                      separatorBuilder: (_, _) => const Divider(height: 18),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _PostCommentTile(
                          comment: comment,
                          onLongPress: () => _openCommentActions(comment),
                          onMoreTap: () => _openCommentActions(comment),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(_isSubmitting ? '...' : 'إرسال'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('post-comment-input'),
                    controller: _controller,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك',
                      filled: true,
                      fillColor: const Color(0xFFF3F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    final payload = await widget.repository.loadComments(postId: widget.postId);
    if (!mounted) {
      return;
    }
    setState(() {
      _comments = payload.comments;
      _isLoading = false;
    });
    widget.onCommentCountChanged(payload.comments.length);
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = await widget.repository.addComment(
        postId: widget.postId,
        bodyText: body,
      );
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {
        _comments = payload.comments;
        _isSubmitting = false;
      });
      widget.onCommentCountChanged(payload.comments.length);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      _showError(error.toString());
    }
  }

  Future<void> _openCommentActions(PostCommentData comment) async {
    if (!comment.canEdit && !comment.canDelete && !comment.canReport) {
      return;
    }

    final action = await showModalBottomSheet<_PostCommentAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PostCommentActionsSheet(comment: comment);
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _PostCommentAction.edit:
        await _editComment(comment);
      case _PostCommentAction.delete:
        await _deleteComment(comment);
      case _PostCommentAction.report:
        await _reportComment(comment);
    }
  }

  Future<void> _editComment(PostCommentData comment) async {
    if (!comment.canEdit) {
      return;
    }

    final bodyText = await showDialog<String>(
      context: context,
      builder: (context) {
        return _PostCommentEditDialog(initialBodyText: comment.bodyText);
      },
    );

    if (bodyText == null) {
      return;
    }

    if (bodyText.isEmpty) {
      _showError('محتوى التعليق مطلوب.');
      return;
    }

    try {
      final payload = await widget.repository.updateComment(
        postId: widget.postId,
        commentId: comment.id,
        bodyText: bodyText,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments = payload.comments;
      });
      widget.onCommentCountChanged(payload.comments.length);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تعديل التعليق.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _deleteComment(PostCommentData comment) async {
    if (!comment.canDelete) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف التعليق'),
            content: const Text('هل تريد حذف هذا التعليق من المنشور؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB45A5A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final payload = await widget.repository.deleteComment(
        postId: widget.postId,
        commentId: comment.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments = payload.comments;
      });
      widget.onCommentCountChanged(payload.comments.length);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف التعليق.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _reportComment(PostCommentData comment) async {
    if (!comment.canReport) {
      return;
    }

    try {
      final reasons = await widget.repository.loadReportReasons();
      if (!mounted) {
        return;
      }

      final selectedReason = await showModalBottomSheet<PostReportReasonData>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _PostReportReasonsSheet(
            reasons: reasons.isEmpty
                ? const <PostReportReasonData>[
                    PostReportReasonData(
                      id: 0,
                      reasonKey: 'other',
                      label: 'سبب آخر',
                      description: 'إرسال بلاغ عام لمراجعة الأدمن.',
                    ),
                  ]
                : reasons,
          );
        },
      );

      if (selectedReason == null) {
        return;
      }

      await widget.repository.reportComment(
        postId: widget.postId,
        commentId: comment.id,
        reasonKey: selectedReason.reasonKey,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال بلاغ التعليق.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PostCommentTile extends StatelessWidget {
  const _PostCommentTile({
    required this.comment,
    required this.onLongPress,
    required this.onMoreTap,
  });

  final PostCommentData comment;
  final VoidCallback onLongPress;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final hasActions =
        comment.canEdit || comment.canDelete || comment.canReport;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: hasActions ? onLongPress : null,
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: metrics.spacing(17, min: 16, max: 19),
            backgroundImage: AssetImage(comment.authorAvatarAsset),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _PostScreenState._primaryBlue,
                            fontSize: metrics.font(13, min: 12, max: 14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasActions)
                        InkWell(
                          onTap: onMoreTap,
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: _PostScreenState._primaryBlue,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    comment.bodyText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: metrics.font(13, min: 12, max: 14),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.createdAtLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF9DB2CE),
                      fontSize: metrics.font(10, min: 9, max: 11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCommentActionsSheet extends StatelessWidget {
  const _PostCommentActionsSheet({required this.comment});

  final PostCommentData comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E6F2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'اختيارات التعليق',
                style: TextStyle(
                  color: _PostScreenState._primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (comment.canEdit)
                _PostMenuTile(
                  icon: Icons.edit_note_rounded,
                  title: 'تعديل التعليق',
                  subtitle: 'تعديل نص التعليق بدون تحديث الصفحة',
                  onTap: () =>
                      Navigator.of(context).pop(_PostCommentAction.edit),
                ),
              if (comment.canDelete)
                _PostMenuTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'حذف التعليق',
                  subtitle: 'إزالة التعليق من المنشور',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_PostCommentAction.delete),
                ),
              if (comment.canReport)
                _PostMenuTile(
                  icon: Icons.outlined_flag_rounded,
                  title: 'إبلاغ عن تعليق',
                  subtitle: 'إرسال البلاغ للإدارة مع اختيار السبب',
                  danger: true,
                  onTap: () =>
                      Navigator.of(context).pop(_PostCommentAction.report),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCommentEditDialog extends StatefulWidget {
  const _PostCommentEditDialog({required this.initialBodyText});

  final String initialBodyText;

  @override
  State<_PostCommentEditDialog> createState() => _PostCommentEditDialogState();
}

class _PostCommentEditDialogState extends State<_PostCommentEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBodyText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تعديل التعليق'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          maxLines: 5,
          minLines: 2,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'اكتب التعليق',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _PostScreenState._primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _PostReportReasonsSheet extends StatelessWidget {
  const _PostReportReasonsSheet({required this.reasons});

  final List<PostReportReasonData> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E6F2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'سبب البلاغ',
              style: TextStyle(
                color: _PostScreenState._primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: reasons.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final reason = reasons[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reason.label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _PostScreenState._primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: reason.description.isEmpty
                        ? null
                        : Text(
                            reason.description,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF6F7C8F),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: _PostScreenState._primaryBlue,
                    ),
                    onTap: () => Navigator.of(context).pop(reason),
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

class _PostNotificationsSheet extends StatelessWidget {
  const _PostNotificationsSheet({required this.payload});

  final PostNotificationsPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E6F2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'الإشعارات',
              style: TextStyle(
                color: _PostScreenState._primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: payload.notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد إشعارات حاليا',
                        style: TextStyle(
                          color: _PostScreenState._primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: payload.notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 18),
                      itemBuilder: (context, index) {
                        final notification = payload.notifications[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              notification.message,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: notification.isRead
                                    ? const Color(0xFF6F7C8F)
                                    : _PostScreenState._primaryBlue,
                                fontSize: 13,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.createdAtLabel,
                              style: const TextStyle(
                                color: Color(0xFF9DB2CE),
                                fontSize: 10,
                              ),
                            ),
                          ],
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
