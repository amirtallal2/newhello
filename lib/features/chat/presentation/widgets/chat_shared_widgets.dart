import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          if (showSearch)
            _SearchButton(onTap: onSearchTap)
          else
            const SizedBox(width: 38, height: 37),
          const Spacer(),
          const Text(
            'المحادثات',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.29,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onEditTap,
            child: const Text(
              'تعديل',
              style: TextStyle(
                color: ChatScreenPalette.primaryBlue,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                height: 1.29,
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
  });

  final String title;
  final String preview;
  final String? date;
  final ChatReadStyle readStyle;
  final bool isPhotoMessage;
  final bool showStatus;
  final Color statusColor;
  final Widget? avatarChild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 74,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              Icons.chevron_left_rounded,
              color: Colors.black.withValues(alpha: 0.3),
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (date != null)
                        Text(
                          date!,
                          style: const TextStyle(
                            color: ChatScreenPalette.mutedText,
                            fontSize: 14,
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
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ReadCheckIcon(style: readStyle),
                      if (readStyle != ChatReadStyle.none)
                        const SizedBox(width: 6),
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
                                          style: const TextStyle(
                                            color: ChatScreenPalette.mutedText,
                                            fontSize: 14,
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
            const SizedBox(width: 14),
            Stack(
              clipBehavior: Clip.none,
              children: [
                ChatAvatar(child: avatarChild),
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
  const ChatAvatar({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
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
      child: Center(
        child:
            child ??
            const Icon(Icons.person_rounded, color: Colors.white, size: 28),
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
                  const SizedBox(height: 48),
                  ChatScreenHeader(
                    showSearch: showSearch,
                    onSearchTap: onSearchTap,
                    onEditTap: onEditTap,
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: ChatScreenPalette.border,
                  ),
                  const SizedBox(height: 11),
                  ChatPrimaryTabs(
                    activeTab: activeTab,
                    onDiscoverTap: onDiscoverTap,
                    onMessagesTap: onMessagesTap,
                    onFriendsTap: onFriendsTap,
                  ),
                  const SizedBox(height: 12),
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: underlineWidth,
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
    return Semantics(
      label: 'chat-search-button',
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 38,
            height: 37,
            decoration: const BoxDecoration(
              color: ChatScreenPalette.lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              color: ChatScreenPalette.primaryBlue,
              size: 18,
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
