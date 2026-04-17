import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final List<String> _recentSearches = <String>[
    'Mo',
    'Abdullahman Mohamed',
    'Youssef Sherif',
  ];

  final String _query = 'Mo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 54),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(query: _query),
            ),
            const SizedBox(height: 26),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'عمليات البحث الأخيرة',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: ChatScreenPalette.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ..._recentSearches.asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;

                      return _RecentSearchRow(
                        label: value,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.chatConversation);
                        },
                        onDeleteTap: () {
                          setState(() {
                            _recentSearches.removeAt(index);
                          });
                        },
                      );
                    }),
                    const Spacer(),
                    const _KeyboardMock(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 16, color: Color(0xFF2F3036)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: query,
                      style: const TextStyle(
                        color: Color(0xFF1F2024),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const WidgetSpan(child: SizedBox(width: 1)),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: SizedBox(
                        width: 1.5,
                        height: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Color(0xFF8062A5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.label,
    required this.onTap,
    required this.onDeleteTap,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Semantics(
              label: 'chat-search-delete-$label',
              button: true,
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onDeleteTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8F9098),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1F2024),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardMock extends StatelessWidget {
  const _KeyboardMock();

  static const List<String> _topRow = [
    'Q',
    'W',
    'E',
    'R',
    'T',
    'Y',
    'U',
    'I',
    'O',
    'P',
  ];
  static const List<String> _middleRow = [
    'A',
    'S',
    'D',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
  ];
  static const List<String> _bottomRow = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 293,
      width: double.infinity,
      color: const Color(0xFFD4D6DD),
      padding: const EdgeInsets.fromLTRB(3, 8, 3, 16),
      child: Column(
        children: [
          _KeyboardRow(keys: _topRow),
          const SizedBox(height: 11),
          _KeyboardRow(keys: _middleRow, horizontalPadding: 19),
          const SizedBox(height: 11),
          Row(
            children: [
              const _KeyboardActionKey(
                width: 42,
                height: 43,
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_upward_rounded, size: 22),
              ),
              const SizedBox(width: 6),
              Expanded(child: _KeyboardRow(keys: _bottomRow, compact: true)),
              const SizedBox(width: 6),
              const _KeyboardActionKey(
                width: 42,
                height: 42,
                backgroundColor: Color(0xFFC5C6CC),
                child: Icon(Icons.backspace_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _KeyboardActionKey(
                width: 87,
                height: 43,
                backgroundColor: Color(0xFFC5C6CC),
                text: '123',
              ),
              const SizedBox(width: 6),
              const _KeyboardActionKey(
                width: 42,
                height: 42,
                backgroundColor: Color(0xFFD4D6DD),
                child: Icon(Icons.sentiment_satisfied_alt_outlined, size: 22),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: _KeyboardActionKey(
                  width: double.infinity,
                  height: 43,
                  backgroundColor: Colors.white,
                  text: 'space',
                ),
              ),
              const SizedBox(width: 6),
              const _KeyboardActionKey(
                width: 42,
                height: 42,
                backgroundColor: Color(0xFFD4D6DD),
                child: Icon(Icons.mic_none_rounded, size: 22),
              ),
              const SizedBox(width: 6),
              const _KeyboardActionKey(
                width: 87,
                height: 43,
                backgroundColor: Color(0xFF285F98),
                text: 'return',
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({
    required this.keys,
    this.horizontalPadding = 0,
    this.compact = false,
  });

  final List<String> keys;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: keys
            .map(
              (key) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _KeyboardLetterKey(
                    label: key,
                    fontSize: compact ? 22 : 24,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _KeyboardLetterKey extends StatelessWidget {
  const _KeyboardLetterKey({required this.label, required this.fontSize});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF1F2024),
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

class _KeyboardActionKey extends StatelessWidget {
  const _KeyboardActionKey({
    required this.width,
    required this.height,
    required this.backgroundColor,
    this.child,
    this.text,
    this.textColor = const Color(0xFF1F2024),
  });

  final double width;
  final double height;
  final Color backgroundColor;
  final Widget? child;
  final String? text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child:
          child ??
          Text(
            text ?? '',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.32,
            ),
          ),
    );
  }
}
