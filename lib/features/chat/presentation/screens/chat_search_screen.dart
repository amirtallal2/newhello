import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/chat_repository.dart';
import '../widgets/chat_shared_widgets.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<ChatSearchPayload> _future;

  @override
  void initState() {
    super.initState();
    _searchController.text = 'Mo';
    _future = ChatRepository.instance.loadSearch(query: _searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    setState(() {
      _future = ChatRepository.instance.loadSearch(query: query);
    });
  }

  Future<void> _deleteEntry(int searchId) async {
    final updated = await ChatRepository.instance.deleteSearchEntry(
      searchId: searchId,
    );
    setState(() {
      _future = Future<ChatSearchPayload>.value(
        ChatSearchPayload(
          query: _searchController.text,
          recentSearches: updated,
          results: const <ChatThreadData>[],
        ),
      );
    });
  }

  Future<void> _openRecent(ChatSearchEntryData entry) async {
    await ChatRepository.instance.rememberSearch(
      label: entry.label,
      threadId: entry.targetThreadId,
    );
    if (!mounted) {
      return;
    }
    if (entry.targetThreadId == null || entry.targetThreadId! < 1) {
      _searchController.text = entry.label;
      _runSearch(entry.label);
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.chatConversation, arguments: entry.targetThreadId);
  }

  Future<void> _openResult(ChatThreadData thread) async {
    await ChatRepository.instance.rememberSearch(
      label: thread.title,
      threadId: thread.id,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.chatConversation, arguments: thread.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: FutureBuilder<ChatSearchPayload>(
          future: _future,
          builder: (context, snapshot) {
            final payload = snapshot.data;
            final recentSearches =
                payload?.recentSearches ?? const <ChatSearchEntryData>[];
            final results = payload?.results ?? const <ChatThreadData>[];

            return Column(
              children: [
                const SizedBox(height: 54),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: _runSearch,
                    onSubmitted: _runSearch,
                  ),
                ),
                const SizedBox(height: 26),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: RefreshIndicator(
                      color: ChatScreenPalette.primaryBlue,
                      onRefresh: () async => _runSearch(_searchController.text),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          _SearchSectionTitle(
                            title: 'نتائج البحث',
                            topPadding: 0,
                          ),
                          if (snapshot.connectionState != ConnectionState.done)
                            const Padding(
                              padding: EdgeInsets.only(top: 42),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (results.isEmpty)
                            const _SearchEmptyState()
                          else
                            ...results.map(
                              (thread) => ChatThreadRow(
                                title: thread.title,
                                preview: thread.previewText,
                                date: thread.messageDateLabel,
                                avatarAsset: thread.avatarAsset,
                                isPhotoMessage: thread.isPhotoPreview,
                                onTap: () => _openResult(thread),
                              ),
                            ),
                          _SearchSectionTitle(
                            title: 'عمليات البحث الأخيرة',
                            topPadding: results.isEmpty ? 18 : 28,
                          ),
                          ...recentSearches.map(
                            (entry) => _RecentSearchRow(
                              label: entry.label,
                              onTap: () => _openRecent(entry),
                              onDeleteTap: () => _deleteEntry(entry.id),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

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
            child: TextField(
              key: const ValueKey('chat-search-field'),
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'ابحث في المحادثات',
              ),
              style: const TextStyle(
                color: Color(0xFF1F2024),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({required this.title, required this.topPadding});

  final String title;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, topPadding, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: ChatScreenPalette.primaryBlue,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Text(
          'لا توجد نتائج مطابقة',
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
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
