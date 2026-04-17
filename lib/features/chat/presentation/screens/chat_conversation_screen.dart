import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class ChatConversationScreen extends StatelessWidget {
  const ChatConversationScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _headerBackground = Color(0xFFF6F6F6);
  static const Color _lineColor = Color(0xFFA6A6AA);
  static const Color _dateChip = Color(0xFFDDDDE9);
  static const Color _inputBorder = Color(0xFF8E8E93);
  static const Color _mutedDark = Color(0x40000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _ConversationHeader(
              onBackTap: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                  return;
                }

                navigator.pushReplacementNamed(AppRoutes.chatMessages);
              },
            ),
            const Expanded(child: _ConversationCanvas()),
            const _MessageComposer(),
          ],
        ),
      ),
    );
  }
}

class _ConversationCanvas extends StatelessWidget {
  const _ConversationCanvas();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/chat_conversation_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(7, 20, 8, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Align(alignment: Alignment.topCenter, child: _AnnouncementBanner()),
            SizedBox(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: _OutgoingBubble(
                width: 162,
                message: 'Good bye!',
                time: '17:47',
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: _DateChip(label: 'Fri, Jul 26'),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _OutgoingBubble(
                width: 187,
                message: 'Good morning!',
                time: '10:10',
                rounded: true,
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: _IncomingBubble(
                width: 234,
                message: 'Do you know what time is it?',
                time: '11:40',
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: _OutgoingBubble(
                width: 262,
                message: 'It’s morning in Egypt',
                time: '11:43',
                emoji: '😎',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: ChatConversationScreen._headerBackground,
        boxShadow: [
          BoxShadow(
            color: ChatConversationScreen._lineColor,
            blurRadius: 0,
            offset: Offset(0, 0.33),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(21, 16, 15, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/chat_unavailable_icon.png',
            width: 30,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 25),
          Image.asset(
            'assets/images/chat_clipboard_icon.png',
            width: 30,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
          const Spacer(),
          const _HeaderIdentity(),
          const SizedBox(width: 10),
          const _HeaderAvatar(),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: onBackTap,
            child: const Icon(
              Icons.chevron_right_rounded,
              color: ChatConversationScreen._primaryBlue,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIdentity extends StatelessWidget {
  const _HeaderIdentity();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'احمد محمد',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اونلاين',
              style: TextStyle(
                color: Color(0xFF34A853),
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(width: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF34A853),
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF9CC4F0), Color(0xFF285F98)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 279,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        children: [
          Image.asset(
            'assets/images/chat_warning_icon.png',
            width: 21,
            height: 21,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'الرجاء الالتزام بالقوانين والحفاظ علي الالفاظ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 21,
      decoration: BoxDecoration(
        color: ChatConversationScreen._dateChip,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33989898),
            blurRadius: 0,
            offset: Offset(0, 0.4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3C3C43),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutgoingBubble extends StatelessWidget {
  const _OutgoingBubble({
    required this.width,
    required this.message,
    required this.time,
    this.emoji,
    this.rounded = false,
  });

  final double width;
  final String message;
  final String time;
  final String? emoji;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34,
      decoration: BoxDecoration(
        color: ChatConversationScreen._primaryBlue,
        borderRadius: rounded
            ? BorderRadius.circular(18)
            : BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    message,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (emoji != null) ...[
                  const SizedBox(width: 7),
                  Text(emoji!, style: const TextStyle(fontSize: 16)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              color: Color(0x40FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  const _IncomingBubble({
    required this.width,
    required this.message,
    required this.time,
  });

  final double width;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: ChatConversationScreen._mutedDark,
            blurRadius: 1.5,
            offset: Offset(1, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 5, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0x40000000),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: ChatConversationScreen._headerBackground,
        boxShadow: [
          BoxShadow(
            color: ChatConversationScreen._lineColor,
            blurRadius: 0,
            offset: Offset(0, -0.33),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          Image.asset(
            'assets/images/chat_add_icon.png',
            width: 30,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 18),
          Image.asset(
            'assets/images/chat_gift_icon.png',
            width: 30,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ChatConversationScreen._inputBorder,
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/chat_gallery_icon.png',
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.high,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    color: ChatConversationScreen._primaryBlue,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/chat_mic_icon.png',
            width: 22,
            height: 22,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}
