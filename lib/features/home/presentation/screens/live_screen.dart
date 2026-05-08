import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/live_repository.dart';
import '../widgets/main_bottom_navigation.dart';
import 'live_room_screen.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

enum _LiveTopTab { live, newest, friends }

class _LiveScreenState extends State<LiveScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _shadow = Color(0x1A000000);

  _LiveTopTab _selectedTab = _LiveTopTab.live;
  final LiveRepository _repository = LiveRepository.instance;
  late Future<List<LiveFeedRoomData>> _roomsFuture;
  bool _isCreatingLive = false;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
  }

  Future<List<LiveFeedRoomData>> _loadRooms() {
    return _repository.listRooms(scope: _scopeValue(_selectedTab));
  }

  Future<void> _refreshRooms() async {
    final future = _loadRooms();
    setState(() {
      _roomsFuture = future;
    });
    await future;
  }

  String _scopeValue(_LiveTopTab tab) {
    switch (tab) {
      case _LiveTopTab.live:
        return 'live';
      case _LiveTopTab.newest:
        return 'newest';
      case _LiveTopTab.friends:
        return 'friends';
    }
  }

  void _selectTab(_LiveTopTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
      _roomsFuture = _loadRooms();
    });
  }

  void _openLiveRoom(BuildContext context, LiveFeedRoomData room) {
    Navigator.of(context).pushNamed(
      AppRoutes.liveRoom,
      arguments: LiveRoomScreenArgs(roomId: room.id),
    );
  }

  Future<void> _openSearchSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveSearchSheet(
        repository: _repository,
        scope: _scopeValue(_selectedTab),
        onRoomTap: (room) {
          Navigator.of(context).pop();
          _openLiveRoom(this.context, room);
        },
      ),
    );
  }

  Future<void> _openNotificationsSheet() async {
    final notifications = await _repository.listNotifications();
    final pkInvites = await _repository.listPkInvites();
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveNotificationsSheet(
        notifications: notifications,
        pkInvites: pkInvites,
        onPkAccept: _acceptPkInvite,
        onPkReject: _rejectPkInvite,
        onNotificationTap: (notification) {
          Navigator.of(context).pop();
          _openLiveRoom(
            this.context,
            LiveFeedRoomData(
              id: notification.roomId,
              title: notification.roomTitle,
              posterAsset: 'assets/images/home149_card1.png',
              viewerCount: 0,
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptPkInvite(LivePkInviteData invite) async {
    try {
      final room = await _repository.acceptPkInvite(inviteId: invite.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await Navigator.of(context).pushNamed(
        AppRoutes.liveRoom,
        arguments: LiveRoomScreenArgs(roomId: room.id),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _roomsFuture = _loadRooms();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _rejectPkInvite(LivePkInviteData invite) async {
    try {
      await _repository.rejectPkInvite(inviteId: invite.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم رفض دعوة PK')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openCreateLiveSheet() async {
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LiveCreateSheet(),
    );

    if (title == null || !mounted) {
      return;
    }

    await _createLiveRoom(title);
  }

  Future<void> _createLiveRoom(String title) async {
    if (_isCreatingLive) {
      return;
    }

    setState(() {
      _isCreatingLive = true;
    });

    try {
      final room = await _repository.createRoom(title: title);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedTab = _LiveTopTab.live;
        _roomsFuture = _loadRooms();
        _isCreatingLive = false;
      });

      await Navigator.of(context).pushNamed(
        AppRoutes.liveRoom,
        arguments: LiveRoomScreenArgs(roomId: room.id),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _roomsFuture = _loadRooms();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingLive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final gridCount = metrics.screenWidth >= 900
        ? 4
        : metrics.screenWidth >= 600
        ? 3
        : 2;
    final gridSpacing = metrics.spacing(18, min: 10, max: 24);

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
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/home149_background.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  RefreshIndicator(
                    color: _primaryBlue,
                    onRefresh: _refreshRooms,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        metrics.pageHorizontalPadding(compact: 10, regular: 12),
                        metrics.spacing(60, min: 42, max: 64),
                        metrics.pageHorizontalPadding(compact: 10, regular: 12),
                        24,
                      ),
                      child: ResponsiveContent(
                        maxWidth: 520,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LiveHeaderRow(
                              selectedTab: _selectedTab,
                              onTabSelected: _selectTab,
                              onSearchTap: _openSearchSheet,
                              onNotificationTap: _openNotificationsSheet,
                            ),
                            SizedBox(
                              height: metrics.spacing(30, min: 20, max: 34),
                            ),
                            const _LiveHeroBanner(),
                            SizedBox(
                              height: metrics.spacing(14, min: 10, max: 18),
                            ),
                            _LiveCreateButton(
                              isLoading: _isCreatingLive,
                              onTap: _openCreateLiveSheet,
                            ),
                            SizedBox(
                              height: metrics.spacing(22, min: 18, max: 28),
                            ),
                            FutureBuilder<List<LiveFeedRoomData>>(
                              future: _roomsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 48),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'تعذر تحميل اللايف الآن',
                                          style: TextStyle(
                                            color: _primaryBlue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _roomsFuture = _loadRooms();
                                            });
                                          },
                                          child: const Text('إعادة المحاولة'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final rooms = snapshot.data ?? const [];
                                if (rooms.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 48),
                                    child: Center(
                                      child: Text(
                                        'لا يوجد بث مباشر الآن',
                                        style: TextStyle(
                                          color: _primaryBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: rooms.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridCount,
                                        crossAxisSpacing: gridSpacing,
                                        mainAxisSpacing: metrics.spacing(
                                          15,
                                          min: 12,
                                          max: 20,
                                        ),
                                        childAspectRatio: metrics.isTablet
                                            ? 158 / 160
                                            : 158 / 145,
                                      ),
                                  itemBuilder: (context, index) {
                                    final room = rooms[index];
                                    return _LivePosterCard(
                                      key: ValueKey('live-room-card-$index'),
                                      data: room,
                                      onTap: () => _openLiveRoom(context, room),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.live,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveHeaderRow extends StatelessWidget {
  const _LiveHeaderRow({
    required this.selectedTab,
    required this.onTabSelected,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final _LiveTopTab selectedTab;
  final ValueChanged<_LiveTopTab> onTabSelected;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Row(
      children: [
        _LiveCircleIconButton(
          semanticsLabel: 'live-search',
          onTap: onSearchTap,
          child: const Icon(
            Icons.search_rounded,
            color: _LiveScreenState._primaryBlue,
            size: 18,
          ),
        ),
        SizedBox(width: metrics.spacing(15, min: 10, max: 16)),
        _LiveNotificationButton(onTap: onNotificationTap),
        const Spacer(),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              _LiveTopTabButton(
                label: 'بث مباشر',
                width: metrics.spacing(58, min: 42, max: 60),
                isActive: selectedTab == _LiveTopTab.live,
                onTap: () => onTabSelected(_LiveTopTab.live),
              ),
              SizedBox(width: metrics.spacing(18, min: 12, max: 24)),
              _LiveTopTabButton(
                label: 'جديد',
                width: metrics.spacing(34, min: 26, max: 36),
                isActive: selectedTab == _LiveTopTab.newest,
                onTap: () => onTabSelected(_LiveTopTab.newest),
              ),
              SizedBox(width: metrics.spacing(18, min: 12, max: 24)),
              _LiveTopTabButton(
                label: 'اصدقاء',
                width: metrics.spacing(47, min: 36, max: 50),
                isActive: selectedTab == _LiveTopTab.friends,
                onTap: () => onTabSelected(_LiveTopTab.friends),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveTopTabButton extends StatelessWidget {
  const _LiveTopTabButton({
    required this.label,
    required this.width,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final double width;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : _LiveScreenState._lightBlue,
              fontSize: metrics.font(15, min: 13, max: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: metrics.spacing(5, min: 4, max: 6)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            height: 1,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveHeroBanner extends StatelessWidget {
  const _LiveHeroBanner();

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/home149_banner.png',
            width: double.infinity,
            height: metrics.spacing(134, min: 112, max: 148),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned(
          top: metrics.spacing(58, min: 48, max: 62),
          child: Text(
            'اهلآ بكم في اللايف الخاص بنـا',
            style: TextStyle(
              color: Colors.white,
              fontSize: metrics.font(15, min: 13, max: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: Row(
            children: List.generate(
              4,
              (index) => Container(
                width: 5,
                height: 5,
                margin: EdgeInsets.only(left: index == 3 ? 0 : 2),
                decoration: BoxDecoration(
                  color: index == 0
                      ? _LiveScreenState._primaryBlue
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveCreateButton extends StatelessWidget {
  const _LiveCreateButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Semantics(
      label: 'create-live-video',
      button: true,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: metrics.spacing(52, min: 48, max: 56),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF285F98), Color(0xFF3C90FF)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            boxShadow: const [
              BoxShadow(
                color: _LiveScreenState._shadow,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                SizedBox(width: metrics.spacing(8, min: 6, max: 10)),
                Text(
                  isLoading ? 'جاري إنشاء اللايف...' : 'إنشاء لايف فيديو',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.font(15, min: 14, max: 17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveCreateSheet extends StatefulWidget {
  const _LiveCreateSheet();

  @override
  State<_LiveCreateSheet> createState() => _LiveCreateSheetState();
}

class _LiveCreateSheetState extends State<_LiveCreateSheet> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'لايف جديد');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_titleController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            metrics.spacing(20, min: 16, max: 24),
            metrics.spacing(18, min: 16, max: 22),
            metrics.spacing(20, min: 16, max: 24),
            metrics.spacing(20, min: 18, max: 26),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'إنشاء لايف فيديو حقيقي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _LiveScreenState._primaryBlue,
                    fontSize: metrics.font(18, min: 17, max: 20),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم إنشاء غرفة لايف في قاعدة البيانات وربطها مباشرة بـ Agora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'اسم اللايف',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('ابدأ اللايف الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _LiveScreenState._primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePosterCard extends StatelessWidget {
  const _LivePosterCard({super.key, required this.data, required this.onTap});

  final LiveFeedRoomData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: _LiveScreenState._shadow,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                data.posterAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                left: metrics.spacing(8, min: 6, max: 9),
                top: metrics.spacing(8, min: 6, max: 9),
                child: Container(
                  width: metrics.spacing(20, min: 18, max: 22),
                  height: metrics.spacing(20, min: 18, max: 22),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF285F98), Color(0xFF3C90FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: metrics.size(8).clamp(7, 9).toDouble(),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Text(
                          '${data.viewerCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: metrics.font(5, min: 5, max: 6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: metrics.spacing(8, min: 6, max: 9),
                bottom: metrics.spacing(8, min: 6, max: 9),
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.font(5, min: 5, max: 6),
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.relationshipStatus == 'friends' ||
                  data.relationshipStatus == 'following')
                Positioned(
                  right: metrics.spacing(8, min: 6, max: 9),
                  top: metrics.spacing(8, min: 6, max: 9),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.spacing(7, min: 6, max: 8),
                      vertical: metrics.spacing(3, min: 2, max: 4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data.relationshipStatus == 'friends' ? 'صديق' : 'متابع',
                      style: TextStyle(
                        color: _LiveScreenState._primaryBlue,
                        fontSize: metrics.font(7, min: 6, max: 8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCircleIconButton extends StatelessWidget {
  const _LiveCircleIconButton({
    required this.onTap,
    required this.child,
    required this.semanticsLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: metrics.spacing(32, min: 30, max: 36),
          height: metrics.spacing(32, min: 30, max: 36),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _LiveScreenState._shadow,
                blurRadius: 3,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _LiveNotificationButton extends StatelessWidget {
  const _LiveNotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LiveCircleIconButton(
      semanticsLabel: 'live-notification',
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: _LiveScreenState._primaryBlue,
            size: 18,
          ),
          Positioned(
            top: -5,
            right: -7,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: _LiveScreenState._primaryBlue,
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
    );
  }
}

class _LiveSearchSheet extends StatefulWidget {
  const _LiveSearchSheet({
    required this.repository,
    required this.scope,
    required this.onRoomTap,
  });

  final LiveRepository repository;
  final String scope;
  final ValueChanged<LiveFeedRoomData> onRoomTap;

  @override
  State<_LiveSearchSheet> createState() => _LiveSearchSheetState();
}

class _LiveSearchSheetState extends State<_LiveSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<LiveFeedRoomData>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = widget.repository.listRooms(scope: widget.scope);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String value) {
    setState(() {
      _resultsFuture = widget.repository.listRooms(
        scope: widget.scope,
        query: value.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'البحث في اللايف',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _LiveScreenState._primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                textAlign: TextAlign.right,
                onChanged: _runSearch,
                decoration: InputDecoration(
                  hintText: 'ابحث بعنوان اللايف أو المضيف',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<LiveFeedRoomData>>(
                  future: _resultsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final results = snapshot.data ?? const <LiveFeedRoomData>[];
                    if (results.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'لا توجد نتائج الآن',
                            style: TextStyle(
                              color: _LiveScreenState._primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final room = results[index];
                        return ListTile(
                          onTap: () => widget.onRoomTap(room),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              room.posterAsset,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            room.title,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${room.viewerCount} مشاهد',
                            textAlign: TextAlign.right,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveNotificationsSheet extends StatelessWidget {
  const _LiveNotificationsSheet({
    required this.notifications,
    required this.pkInvites,
    required this.onPkAccept,
    required this.onPkReject,
    required this.onNotificationTap,
  });

  final List<LiveNotificationData> notifications;
  final List<LivePkInviteData> pkInvites;
  final Future<void> Function(LivePkInviteData invite) onPkAccept;
  final Future<void> Function(LivePkInviteData invite) onPkReject;
  final ValueChanged<LiveNotificationData> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.64;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إشعارات اللايف',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _LiveScreenState._primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (pkInvites.isNotEmpty) ...[
                ...pkInvites.map(
                  (invite) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'دعوة PK من ${invite.senderName}',
                            style: const TextStyle(
                              color: _LiveScreenState._primaryBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invite.roomTitle}\n${invite.createdAtLabel}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => onPkAccept(invite),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _LiveScreenState._primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('قبول'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => onPkReject(invite),
                                  child: const Text('رفض'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 18),
              ],
              if (notifications.isEmpty && pkInvites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'لا توجد إشعارات الآن',
                      style: TextStyle(
                        color: _LiveScreenState._primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        onTap: () => onNotificationTap(notification),
                        title: Text(
                          notification.title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${notification.message}\n${notification.roomTitle}',
                          textAlign: TextAlign.right,
                        ),
                        trailing: Text(
                          notification.createdAtLabel,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
