import 'package:flutter/material.dart';

import '../../../../core/widgets/resolved_image.dart';
import '../../data/chat_repository.dart';

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

  final Set<int> _selectedThreadIds = <int>{};
  late Future<List<ChatThreadData>> _future;

  @override
  void initState() {
    super.initState();
    _future = ChatRepository.instance.loadSelectionThreads();
  }

  Future<void> _refresh() async {
    final future = ChatRepository.instance.loadSelectionThreads();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _runBulkAction(String action) async {
    if (_selectedThreadIds.isEmpty) {
      return;
    }
    try {
      await ChatRepository.instance.bulkAction(
        threadIds: _selectedThreadIds.toList(),
        action: action,
      );
      setState(() {
        _selectedThreadIds.clear();
        _future = ChatRepository.instance.loadSelectionThreads();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _toggleSelection(int threadId) {
    setState(() {
      if (_selectedThreadIds.contains(threadId)) {
        _selectedThreadIds.remove(threadId);
      } else {
        _selectedThreadIds.add(threadId);
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
        child: FutureBuilder<List<ChatThreadData>>(
          future: _future,
          builder: (context, snapshot) {
            final threads = snapshot.data ?? const <ChatThreadData>[];
            final hasSelection = _selectedThreadIds.isNotEmpty;

            return Column(
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
                  child: snapshot.connectionState != ConnectionState.done
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          color: const Color(0xFFEFEFF4),
                          child: RefreshIndicator(
                            color: _primaryBlue,
                            onRefresh: _refresh,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: threads.length,
                              separatorBuilder: (context, _) => const Divider(
                                height: 1,
                                thickness: 0.33,
                                indent: 118,
                                color: _separator,
                              ),
                              itemBuilder: (context, index) {
                                final thread = threads[index];
                                return _SelectionRow(
                                  data: thread,
                                  isSelected: _selectedThreadIds.contains(
                                    thread.id,
                                  ),
                                  onTap: () => _toggleSelection(thread.id),
                                );
                              },
                            ),
                          ),
                        ),
                ),
                Container(
                  height: 83,
                  color: _surface,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 17,
                        right: 16,
                        child: GestureDetector(
                          onTap: hasSelection
                              ? () => _runBulkAction('delete')
                              : null,
                          child: Text(
                            'مسح',
                            style: TextStyle(
                              color: hasSelection
                                  ? const Color(0xFFB45A5A)
                                  : _disabledAction,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 17,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: hasSelection
                                ? () => _runBulkAction('mark_read')
                                : null,
                            child: Text(
                              'قرائة الكل',
                              style: TextStyle(
                                color: hasSelection
                                    ? _primaryBlue
                                    : _disabledAction,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.4,
                              ),
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
            );
          },
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

  final ChatThreadData data;
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
              data.messageDateLabel,
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
                    data.previewText,
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
                _SelectionAvatar(avatarAsset: data.avatarAsset),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _selectionColor(data.statusColorHex),
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
  const _SelectionAvatar({required this.avatarAsset});

  final String avatarAsset;

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
      clipBehavior: Clip.antiAlias,
      child: avatarAsset.trim().isNotEmpty
          ? ResolvedImage(path: avatarAsset, fit: BoxFit.cover)
          : const Icon(Icons.person_rounded, color: Colors.white, size: 28),
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

Color _selectionColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16) ?? 0x34A853;
  return Color(0xFF000000 | value);
}
