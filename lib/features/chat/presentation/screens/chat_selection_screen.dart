import 'package:flutter/material.dart';

class ChatSelectionScreen extends StatefulWidget {
  const ChatSelectionScreen({super.key});

  @override
  State<ChatSelectionScreen> createState() => _ChatSelectionScreenState();
}

class _ChatSelectionScreenState extends State<ChatSelectionScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _mutedText = Color(0xFF8E8E93);
  static const Color _separator = Color(0x4A3C3C43);
  static const Color _surface = Color(0xFFF6F6F6);
  static const Color _disabledAction = Color(0xFFC7C7CC);

  final Set<int> _selectedIndexes = <int>{0};

  static const List<_SelectableThreadData> _threads = [
    _SelectableThreadData(
      title: 'محمد احمد',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      date: '11/16/19',
      statusColor: Color(0xFF34A853),
      initiallySelected: true,
    ),
    _SelectableThreadData(
      title: 'محمد احمد',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      date: '11/16/19',
      statusColor: Color(0xFFEA4335),
    ),
    _SelectableThreadData(
      title: 'محمد احمد',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      date: '11/16/19',
      statusColor: Color(0xFF34A853),
    ),
    _SelectableThreadData(
      title: 'محمد احمد',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      date: '11/16/19',
      statusColor: Color(0xFF34A853),
    ),
    _SelectableThreadData(
      title: 'محمد احمد',
      preview: 'كيف حالك يارب ان تكون بخير ؟؟',
      date: '11/16/19',
      statusColor: Color(0xFF34A853),
    ),
  ];

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
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
            Container(
              height: 140,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 54, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                    child: const Text(
                      'موافقة',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.29,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'المحادثات',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.23,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEFEFF4),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _threads.length,
                  separatorBuilder: (context, _) => const Divider(
                    height: 1,
                    thickness: 0.33,
                    indent: 118,
                    color: _separator,
                  ),
                  itemBuilder: (context, index) {
                    final thread = _threads[index];
                    return _SelectionRow(
                      data: thread,
                      isSelected: _selectedIndexes.contains(index),
                      onTap: () => _toggleSelection(index),
                    );
                  },
                ),
              ),
            ),
            Container(
              height: 83,
              color: _surface,
              child: Stack(
                children: [
                  const Positioned(
                    top: 17,
                    right: 16,
                    child: Text(
                      'مسح',
                      style: TextStyle(
                        color: _disabledAction,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 17,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'قرائة الكل',
                        style: TextStyle(
                          color: _disabledAction,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 121,
                    right: 120,
                    bottom: 9,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
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

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _SelectableThreadData data;
  final bool isSelected;
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
            Text(
              data.date,
              style: const TextStyle(
                color: _ChatSelectionScreenState._mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.done_all_rounded,
              color: _ChatSelectionScreenState._primaryBlue,
              size: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.33,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _ChatSelectionScreenState._mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const _SelectionAvatar(),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data.statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            _SelectionCircle(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _SelectionAvatar extends StatelessWidget {
  const _SelectionAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF9CC4F0), Color(0xFF285F98)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 21,
        height: 21,
        decoration: const BoxDecoration(
          color: _ChatSelectionScreenState._primaryBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
    }

    return Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x993C3C43), width: 1.5),
      ),
    );
  }
}

class _SelectableThreadData {
  const _SelectableThreadData({
    required this.title,
    required this.preview,
    required this.date,
    required this.statusColor,
    this.initiallySelected = false,
  });

  final String title;
  final String preview;
  final String date;
  final Color statusColor;
  final bool initiallySelected;
}
