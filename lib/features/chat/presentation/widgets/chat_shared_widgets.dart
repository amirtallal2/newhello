import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/resolved_image.dart';

class ChatScreenPalette {
  static const Color primaryBlue = Color(0xFF285F98);
  static const Color lightBlue = Color(0xFFB4D1EF);
  static const Color mutedText = Color(0xFF8E8E93);
  static const Color border = Color(0x4A3C3C43);
  static const Color pageBackground = Color(0xFFEFEFF4);
  static const Color appBarBackground = Color(0xFFF6F6F6);
}

enum ChatPrimaryTab { discover, messages, friends }

enum ChatReadStyle { none, single, double }

class ChatScreenHeader extends StatelessWidget {
  const ChatScreenHeader({
    super.key,
    required this.onEditTap,
    this.onSearchTap,
    this.showSearch = false,
  });

  final VoidCallback onEditTap;
  final VoidCallback? onSearchTap;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.pageHorizontalPadding(compact: 14, regular: 18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: showSearch
                ? _SearchButton(onTap: onSearchTap)
                : SizedBox(
                    width: metrics.spacing(38, min: 34, max: 42),
                    height: metrics.spacing(37, min: 34, max: 42),
                  ),
          ),
          Text(
            'المحادثات',
            style: TextStyle(
              color: Colors.black,
              fontSize: metrics.font(17, min: 15, max: 18),
              fontWeight: FontWeight.w600,
              height: 1.29,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onEditTap,
              child: Text(
                'تعديل',
                style: TextStyle(
                  color: ChatScreenPalette.primaryBlue,
                  fontSize: metrics.font(17, min: 15, max: 18),
                  fontWeight: FontWeight.w400,
                  height: 1.29,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPrimaryTabs extends StatelessWidget {
  const ChatPrimaryTabs({
    super.key,
    required this.activeTab,
    required this.onDiscoverTap,
    required this.onMessagesTap,
    required this.onFriendsTap,
  });

  final ChatPrimaryTab activeTab;
  final VoidCallback onDiscoverTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onFriendsTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TopTab(
            label: 'اكتشف',
            isActive: activeTab == ChatPrimaryTab.discover,
            underlineWidth: 46,
            onTap: onDiscoverTap,
          ),
          _TopTab(
            label: 'رسالة',
            isActive: activeTab == ChatPrimaryTab.messages,
            underlineWidth: 36,
            onTap: onMessagesTap,
          ),
          _TopTab(
            label: 'الاصدقاء',
            isActive: activeTab == ChatPrimaryTab.friends,
            underlineWidth: 56,
            onTap: onFriendsTap,
          ),
        ],
      ),
    );
  }
}

class ChatThreadRow extends StatelessWidget {
  const ChatThreadRow({
    super.key,
    required this.title,
    required this.onTap,
    this.preview = '',
    this.date,
    this.readStyle = ChatReadStyle.none,
    this.isPhotoMessage = false,
    this.showStatus = true,
    this.statusColor = const Color(0xFF34A853),
    this.avatarChild,
    this.avatarAsset,
    this.onAvatarTap,
  });

  final String title;
  final String preview;
  final String? date;
  final ChatReadStyle readStyle;
  final bool isPhotoMessage;
  final bool showStatus;
  final Color statusColor;
  final Widget? avatarChild;
  final String? avatarAsset;
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: metrics.spacing(74, min: 68, max: 82),
        ),
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: metrics.spacing(16, min: 12, max: 18),
          vertical: metrics.spacing(11, min: 10, max: 14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_left_rounded,
              color: Colors.black.withValues(alpha: 0.3),
              size: metrics.size(20).clamp(18, 22).toDouble(),
            ),
            SizedBox(width: metrics.spacing(14, min: 10, max: 16)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (date != null)
                        Text(
                          date!,
                          style: TextStyle(
                            color: ChatScreenPalette.mutedText,
                            fontSize: metrics.font(14, min: 12, max: 15),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      if (date != null) const Spacer(),
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: metrics.font(16, min: 14, max: 17),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.spacing(8, min: 6, max: 10)),
                  Row(
                    children: [
                      _ReadCheckIcon(style: readStyle),
                      if (readStyle != ChatReadStyle.none)
                        SizedBox(width: metrics.spacing(6, min: 4, max: 8)),
                      Expanded(
                        child: preview.isEmpty
                            ? const SizedBox.shrink()
                            : Directionality(
                                textDirection: TextDirection.rtl,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: isPhotoMessage
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'صورة',
                                              style: TextStyle(
                                                color:
                                                    ChatScreenPalette.mutedText,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.photo_camera_outlined,
                                              color:
                                                  ChatScreenPalette.mutedText,
                                              size: 14,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          preview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: ChatScreenPalette.mutedText,
                                            fontSize: metrics.font(
                                              14,
                                              min: 12,
                                              max: 15,
                                            ),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: metrics.spacing(14, min: 10, max: 16)),
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: ChatAvatar(
                    avatarAsset: avatarAsset,
                    child: avatarChild,
                  ),
                ),
                if (showStatus)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, this.child, this.avatarAsset});

  final Widget? child;
  final String? avatarAsset;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final avatarSize = metrics.spacing(52, min: 44, max: 56);

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF285F98), Color(0xFF4C7DB0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child != null
          ? Center(child: child)
          : (avatarAsset != null && avatarAsset!.trim().isNotEmpty)
          ? ResolvedImage(
              path: avatarAsset!,
              fit: BoxFit.cover,
              width: avatarSize,
              height: avatarSize,
            )
          : Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: metrics.size(28).clamp(22, 30).toDouble(),
              ),
            ),
    );
  }
}

class ChatScreenFrame extends StatelessWidget {
  const ChatScreenFrame({
    super.key,
    required this.activeTab,
    required this.body,
    required this.onEditTap,
    required this.onDiscoverTap,
    required this.onMessagesTap,
    required this.onFriendsTap,
    this.onSearchTap,
    this.showSearch = false,
  });

  final ChatPrimaryTab activeTab;
  final Widget body;
  final VoidCallback onEditTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onFriendsTap;
  final VoidCallback? onSearchTap;
  final bool showSearch;

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
            Container(
              color: ChatScreenPalette.appBarBackground,
              child: Column(
                children: [
                  SizedBox(height: metrics.spacing(48, min: 36, max: 52)),
                  ChatScreenHeader(
                    showSearch: showSearch,
                    onSearchTap: onSearchTap,
                    onEditTap: onEditTap,
                  ),
                  SizedBox(height: metrics.spacing(16, min: 12, max: 18)),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: ChatScreenPalette.border,
                  ),
                  SizedBox(height: metrics.spacing(11, min: 8, max: 12)),
                  ChatPrimaryTabs(
                    activeTab: activeTab,
                    onDiscoverTap: onDiscoverTap,
                    onMessagesTap: onMessagesTap,
                    onFriendsTap: onFriendsTap,
                  ),
                  SizedBox(height: metrics.spacing(12, min: 10, max: 14)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: ChatScreenPalette.pageBackground,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.underlineWidth = 34,
  });

  final String label;
  final bool isActive;
  final double underlineWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? ChatScreenPalette.primaryBlue
                  : ChatScreenPalette.lightBlue,
              fontSize: metrics.font(15, min: 13, max: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: metrics.spacing(5, min: 4, max: 6)),
          Container(
            width: metrics.spacing(underlineWidth, min: 28, max: 60),
            height: 1,
            decoration: BoxDecoration(
              color: isActive
                  ? ChatScreenPalette.primaryBlue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Semantics(
      label: 'chat-search-button',
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: metrics.spacing(38, min: 34, max: 42),
            height: metrics.spacing(37, min: 34, max: 42),
            decoration: const BoxDecoration(
              color: ChatScreenPalette.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              color: ChatScreenPalette.primaryBlue,
              size: metrics.size(18).clamp(16, 20).toDouble(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadCheckIcon extends StatelessWidget {
  const _ReadCheckIcon({required this.style});

  final ChatReadStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == ChatReadStyle.none) {
      return const SizedBox.shrink();
    }

    if (style == ChatReadStyle.single) {
      return const Icon(
        Icons.done_rounded,
        color: ChatScreenPalette.primaryBlue,
        size: 14,
      );
    }

    return const Icon(
      Icons.done_all_rounded,
      color: ChatScreenPalette.primaryBlue,
      size: 14,
    );
  }
}
