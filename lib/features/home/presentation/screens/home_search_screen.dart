import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../room/data/room_repository.dart';
import '../../../room/presentation/screens/room_screen.dart';
import '../../../social/data/social_repository.dart';

enum _HomeSearchMode { user, room }

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _searchSurface = Color(0xFFF8F9FE);
  static const Color _textDark = Color(0xFF1F2024);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  _HomeSearchMode _mode = _HomeSearchMode.user;
  bool _isLoading = true;
  List<SocialUserData> _users = const <SocialUserData>[];
  List<RoomData> _rooms = const <RoomData>[];
  List<ChatSearchEntryData> _recentSearches = const <ChatSearchEntryData>[];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait([_loadRecentSearches(), _runSearch()]);
  }

  Future<void> _loadRecentSearches() async {
    try {
      final payload = await ChatRepository.instance.loadSearch(
        query: _searchController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recentSearches = payload.recentSearches;
      });
    } catch (_) {}
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      if (_mode == _HomeSearchMode.user) {
        final users = await SocialRepository.instance.searchUsers(query: query);
        if (!mounted) {
          return;
        }
        setState(() {
          _users = users;
          _isLoading = false;
        });
        return;
      }

      final rooms = await RoomRepository.instance.listRooms(scope: 'newest');
      final filtered = query.isEmpty
          ? rooms
          : rooms.where((room) {
              final searchText =
                  '${room.roomTitle} ${room.cardTitle} ${room.hostName} ${room.roomCode} ${room.roomType} ${room.countryLabel}'
                      .toLowerCase();
              return searchText.contains(query.toLowerCase());
            }).toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _rooms = filtered;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _submitQuery([String? value]) async {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) {
      return;
    }

    await ChatRepository.instance.rememberSearch(label: query, threadId: null);
    await _loadRecentSearches();
  }

  Future<void> _deleteRecent(ChatSearchEntryData entry) async {
    final updated = await ChatRepository.instance.deleteSearchEntry(
      searchId: entry.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches = updated;
    });
  }

  void _applyRecent(ChatSearchEntryData entry) {
    _searchController.text = entry.label;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _runSearch();
  }

  void _switchMode(_HomeSearchMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
    });
    _runSearch();
  }

  void _openUser(SocialUserData user) {
    _submitQuery(user.name);
    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: user.id,
        fallbackName: user.name,
        fallbackAvatarAsset: user.avatarAsset,
        fallbackHandle: user.subtitle,
      ),
    );
  }

  void _openRoom(RoomData room) {
    _submitQuery(room.roomTitle);
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.room, arguments: RoomScreenArgs(roomId: room.id));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final query = _searchController.text.trim();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const SizedBox(height: 54),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FigmaSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onQueryChanged,
                  onSubmitted: _submitQuery,
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchModeTabs(mode: _mode, onChanged: _switchMode),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _primaryBlue),
                      )
                    : query.isEmpty
                    ? _RecentSearchesList(
                        recentSearches: _recentSearches,
                        onTap: _applyRecent,
                        onDeleteTap: _deleteRecent,
                      )
                    : _SearchResultsList(
                        mode: _mode,
                        users: _users,
                        rooms: _rooms,
                        onUserTap: _openUser,
                        onRoomTap: _openRoom,
                      ),
              ),
              if (!keyboardVisible) const _KeyboardMock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaSearchBar extends StatelessWidget {
  const _FigmaSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _HomeSearchScreenState._searchSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 16,
              color: _HomeSearchScreenState._textDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                key: const ValueKey('home-search-field'),
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: _HomeSearchScreenState._textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.42,
                ),
                cursorColor: Color(0xFF8062A5),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '1324521421',
                  hintStyle: TextStyle(
                    color: Color(0xFF8F9098),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchModeTabs extends StatelessWidget {
  const _SearchModeTabs({required this.mode, required this.onChanged});

  final _HomeSearchMode mode;
  final ValueChanged<_HomeSearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SearchModeButton(
            label: 'مستخدم',
            selected: mode == _HomeSearchMode.user,
            onTap: () => onChanged(_HomeSearchMode.user),
          ),
        ),
        const SizedBox(width: 36),
        Expanded(
          child: _SearchModeButton(
            label: 'غرفة',
            selected: mode == _HomeSearchMode.room,
            onTap: () => onChanged(_HomeSearchMode.room),
          ),
        ),
      ],
    );
  }
}

class _SearchModeButton extends StatelessWidget {
  const _SearchModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'home-search-tab-$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 41,
          decoration: BoxDecoration(
            color: selected
                ? _HomeSearchScreenState._primaryBlue
                : _HomeSearchScreenState._lightBlue,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : _HomeSearchScreenState._primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSearchesList extends StatelessWidget {
  const _RecentSearchesList({
    required this.recentSearches,
    required this.onTap,
    required this.onDeleteTap,
  });

  final List<ChatSearchEntryData> recentSearches;
  final ValueChanged<ChatSearchEntryData> onTap;
  final ValueChanged<ChatSearchEntryData> onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'عمليات البحث الأخيرة',
              style: TextStyle(
                color: _HomeSearchScreenState._primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (recentSearches.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'لا توجد عمليات بحث حديثة',
                style: TextStyle(
                  color: _HomeSearchScreenState._primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          ...recentSearches.map(
            (entry) => _RecentSearchRow(
              entry: entry,
              onTap: () => onTap(entry),
              onDeleteTap: () => onDeleteTap(entry),
            ),
          ),
      ],
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.entry,
    required this.onTap,
    required this.onDeleteTap,
  });

  final ChatSearchEntryData entry;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'home-search-delete-${entry.id}',
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
            const Spacer(),
            Text(
              entry.label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _HomeSearchScreenState._textDark,
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

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.mode,
    required this.users,
    required this.rooms,
    required this.onUserTap,
    required this.onRoomTap,
  });

  final _HomeSearchMode mode;
  final List<SocialUserData> users;
  final List<RoomData> rooms;
  final ValueChanged<SocialUserData> onUserTap;
  final ValueChanged<RoomData> onRoomTap;

  @override
  Widget build(BuildContext context) {
    final isUserMode = mode == _HomeSearchMode.user;
    final itemCount = isUserMode ? users.length : rooms.length;
    if (itemCount == 0) {
      return const Center(
        child: Text(
          'لا توجد نتائج مطابقة',
          style: TextStyle(
            color: _HomeSearchScreenState._primaryBlue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        if (isUserMode) {
          final user = users[index];
          return _UserResultRow(user: user, onTap: () => onUserTap(user));
        }

        final room = rooms[index];
        return _RoomResultRow(room: room, onTap: () => onRoomTap(room));
      },
    );
  }
}

class _UserResultRow extends StatelessWidget {
  const _UserResultRow({required this.user, required this.onTap});

  final SocialUserData user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _HomeSearchScreenState._textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.subtitle,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF8F9098),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: ResolvedImage(
                path: user.avatarAsset,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomResultRow extends StatelessWidget {
  const _RoomResultRow({required this.room, required this.onTap});

  final RoomData room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    room.roomTitle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeSearchScreenState._textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${room.hostName} · ${room.roomCode}',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8F9098),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ResolvedImage(
                path: room.cardImageAsset,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
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
      padding: const EdgeInsets.fromLTRB(3, 8, 3, 6),
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
                  height: 42,
                  backgroundColor: Colors.white,
                  text: 'space',
                ),
              ),
              const SizedBox(width: 6),
              const _KeyboardActionKey(
                width: 87,
                height: 43,
                backgroundColor: _HomeSearchScreenState._primaryBlue,
                text: 'return',
                textColor: Colors.white,
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 141,
            height: 7,
            decoration: BoxDecoration(
              color: _HomeSearchScreenState._primaryBlue,
              borderRadius: BorderRadius.circular(3.5),
            ),
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
                    height: compact ? 43 : 42,
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
  const _KeyboardLetterKey({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

class _KeyboardActionKey extends StatelessWidget {
  const _KeyboardActionKey({
    this.width,
    required this.height,
    required this.backgroundColor,
    this.text,
    this.textColor = Colors.black,
    this.child,
  });

  final double? width;
  final double height;
  final Color backgroundColor;
  final String? text;
  final Color textColor;
  final Widget? child;

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
            color: Color(0x33000000),
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
            ),
          ),
    );
  }
}
