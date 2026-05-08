import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../post/data/post_repository.dart';
import '../../../room/data/room_repository.dart';
import '../../../room/presentation/screens/room_screen.dart';
import '../widgets/main_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF285F98);
  static const Color lightBlue = Color(0xFFB4D1EF);
  static const Color background = Color(0xFFF6F6F6);
  static const Color shadow = Color(0x1A000000);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeTopTab { hashtag, newest, friends }

class _HomeScreenState extends State<HomeScreen> {
  static const List<_HomeCategory> _categories = [
    _HomeCategory(
      title: 'الالعاب',
      color: Color(0xFFFFB752),
      iconAsset: 'assets/images/home_games_icon.png',
    ),
    _HomeCategory(
      title: 'النوادى',
      color: Color(0xFF1DAAE2),
      iconAsset: 'assets/images/home_club_icon.png',
    ),
    _HomeCategory(
      title: 'انشاء غرفة',
      color: Color(0xFF7D44F1),
      iconAsset: 'assets/images/home_create_room_icon.png',
      fontSize: 11,
    ),
  ];

  _HomeTopTab _selectedTab = _HomeTopTab.newest;
  late List<RoomData> _rooms;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _rooms = const <RoomData>[
      RoomData.fallback,
      RoomData(
        id: 2,
        cardTitle: 'خدمة العملاء',
        roomTitle: 'غرفة الدعم المباشر',
        subtitle: 'اهلا وسهلا بكم في روم مصر ام الدنيا',
        roomType: 'دردشة',
        sloganText: 'ابحث عن شخص يمكنه الدردشه معي هالحين',
        countryLabel: 'مصر',
        hostName: 'محمد أحمد',
        hostUserId: 1,
        creatorUserId: 1,
        roomCode: '1512345413',
        cardImageAsset: 'assets/images/home_room_service.png',
        metaIconAsset: 'assets/images/home_pin_icon.png',
        hostAvatarAsset: 'assets/images/profile_avatar.png',
        listenerCount: 30,
        micCount: 9,
        audioEnabled: true,
        agoraChannelName: 'voice-room-1512345413',
        backgroundAsset: 'assets/images/room_background.jpg',
        pendingRequestSeatNumbers: <int>[],
      ),
      RoomData(
        id: 3,
        cardTitle: 'وكالة ولاد الملوك',
        roomTitle: 'وكالة ولاد الملوك',
        subtitle: 'اهلا وسهلا بكم في روم مصر ام الدنيا',
        roomType: 'عائلة',
        sloganText: 'اهلا وسهلا بكم في روم مصر ام الدنيا',
        countryLabel: 'مصر',
        hostName: 'محمد أحمد',
        hostUserId: 1,
        creatorUserId: 1,
        roomCode: '1512345414',
        cardImageAsset: 'assets/images/home_room_1.png',
        metaIconAsset: 'assets/images/home_egypt_flag.png',
        hostAvatarAsset: 'assets/images/profile_avatar.png',
        listenerCount: 30,
        micCount: 9,
        audioEnabled: true,
        agoraChannelName: 'voice-room-1512345414',
        backgroundAsset: 'assets/images/room_background.jpg',
        pendingRequestSeatNumbers: <int>[],
      ),
      RoomData(
        id: 4,
        cardTitle: 'وكالة ولاد الملوك',
        roomTitle: 'وكالة ولاد الملوك',
        subtitle: 'اهلا وسهلا بكم في روم مصر ام الدنيا',
        roomType: 'عائلة',
        sloganText: 'اهلا وسهلا بكم في روم مصر ام الدنيا',
        countryLabel: 'مصر',
        hostName: 'محمد أحمد',
        hostUserId: 1,
        creatorUserId: 1,
        roomCode: '1512345415',
        cardImageAsset: 'assets/images/home_room_2.png',
        metaIconAsset: 'assets/images/home_egypt_flag.png',
        hostAvatarAsset: 'assets/images/profile_avatar.png',
        listenerCount: 30,
        micCount: 9,
        audioEnabled: true,
        agoraChannelName: 'voice-room-1512345415',
        backgroundAsset: 'assets/images/room_background.jpg',
        pendingRequestSeatNumbers: <int>[],
      ),
    ];
    _loadRooms();
    _loadNotificationCount();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await RoomRepository.instance.listRooms(
        scope: _scopeValue(_selectedTab),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rooms = rooms;
      });
    } catch (_) {}
  }

  Future<void> _loadNotificationCount() async {
    try {
      final payload = await PostRepository.instance.loadNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationCount = payload.unreadCount;
      });
    } catch (_) {}
  }

  String _scopeValue(_HomeTopTab tab) {
    switch (tab) {
      case _HomeTopTab.hashtag:
        return 'hashtag';
      case _HomeTopTab.newest:
        return 'newest';
      case _HomeTopTab.friends:
        return 'friends';
    }
  }

  void _selectTab(_HomeTopTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
      _rooms = const <RoomData>[];
    });
    _loadRooms();
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
            Expanded(
              child: Container(
                color: HomeScreen.background,
                child: RefreshIndicator(
                  color: HomeScreen.primaryBlue,
                  onRefresh: _loadRooms,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 60, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderRow(
                          selectedTab: _selectedTab,
                          onTabSelected: _selectTab,
                          onSearchTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.homeSearch);
                          },
                          onNotificationTap: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.homeNotifications);
                            if (!context.mounted) {
                              return;
                            }
                            await _loadNotificationCount();
                          },
                          notificationCount: _notificationCount,
                        ),
                        const SizedBox(height: 45),
                        const _HeroBanner(),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(
                            _categories.length,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == _categories.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: _CategoryButton(
                                  data: _categories[index],
                                  onTap: () async {
                                    final categoryTitle =
                                        _categories[index].title;

                                    if (categoryTitle == 'النوادى') {
                                      await Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.homeClubs);
                                      if (!context.mounted) {
                                        return;
                                      }
                                      await _loadRooms();
                                      return;
                                    }

                                    if (categoryTitle != 'انشاء غرفة') {
                                      return;
                                    }

                                    await Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.roomCreate);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await _loadRooms();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        if (_rooms.isEmpty)
                          _HomeEmptyState(tab: _selectedTab)
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rooms.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 29,
                                  mainAxisSpacing: 25,
                                  childAspectRatio: 158 / 189,
                                ),
                            itemBuilder: (context, index) {
                              return _RoomCard(data: _rooms[index]);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.home,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.selectedTab,
    required this.onTabSelected,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.notificationCount,
  });

  final _HomeTopTab selectedTab;
  final ValueChanged<_HomeTopTab> onTabSelected;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          onTap: onSearchTap,
          semanticsLabel: 'home-search-button',
          child: const Icon(
            Icons.search_rounded,
            color: HomeScreen.primaryBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 15),
        _NotificationButton(
          onTap: onNotificationTap,
          notificationCount: notificationCount,
        ),
        const Spacer(),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              _TopTab(
                label: 'هاشتاق',
                isActive: selectedTab == _HomeTopTab.hashtag,
                onTap: () => onTabSelected(_HomeTopTab.hashtag),
              ),
              const SizedBox(width: 30),
              _TopTab(
                label: 'جديد',
                isActive: selectedTab == _HomeTopTab.newest,
                onTap: () => onTabSelected(_HomeTopTab.newest),
              ),
              const SizedBox(width: 30),
              _TopTab(
                label: 'اصدقاء',
                isActive: selectedTab == _HomeTopTab.friends,
                onTap: () => onTabSelected(_HomeTopTab.friends),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'home-tab-$label',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? HomeScreen.primaryBlue
                      : HomeScreen.lightBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 1,
                color: isActive ? HomeScreen.primaryBlue : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.tab});

  final _HomeTopTab tab;

  @override
  Widget build(BuildContext context) {
    final message = switch (tab) {
      _HomeTopTab.friends => 'لا توجد غرف لأصدقائك حالياً',
      _HomeTopTab.hashtag => 'لا توجد غرف رائجة حالياً',
      _HomeTopTab.newest => 'لا توجد غرف حالياً',
    };

    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HomeScreen.primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/home_banner.png',
            width: double.infinity,
            height: 134,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned(
          right: 14,
          bottom: 16,
          child: Row(
            children: List.generate(
              15,
              (index) => Container(
                width: 5,
                height: 5,
                margin: EdgeInsets.only(left: index == 14 ? 0 : 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0 ? HomeScreen.primaryBlue : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.data, required this.onTap});

  final _HomeCategory data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                data.iconAsset,
                width: 30,
                height: 30,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: data.fontSize,
                    fontWeight: FontWeight.w600,
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

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.data});

  final RoomData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.room, arguments: RoomScreenArgs(roomId: data.id));
      },
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: HomeScreen.shadow,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: ResolvedImage(
                path: data.cardImageAsset,
                width: double.infinity,
                height: 145,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 1),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            data.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: HomeScreen.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            data.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: HomeScreen.lightBlue,
                              fontSize: 6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: ResolvedImage(
                              path: data.metaIconAsset,
                              width: 15,
                              height: 15,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/home_mic_icon.png',
                                width: 15,
                                height: 15,
                                filterQuality: FilterQuality.high,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${data.listenerCount}',
                                style: const TextStyle(
                                  color: HomeScreen.primaryBlue,
                                  fontSize: 11,
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
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.onTap,
    required this.child,
    this.semanticsLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: semanticsLabel != null,
      container: semanticsLabel != null,
      child: InkWell(
        key: semanticsLabel == null ? null : ValueKey(semanticsLabel),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: HomeScreen.shadow,
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onTap,
    required this.notificationCount,
  });

  final VoidCallback onTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return _CircleIconButton(
      onTap: onTap,
      semanticsLabel: 'home-notification-button',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: HomeScreen.primaryBlue,
            size: 18,
          ),
          if (notificationCount > 0)
            Positioned(
              top: -5,
              right: -7,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: HomeScreen.primaryBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  notificationCount > 9 ? '9+' : '$notificationCount',
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

class _HomeCategory {
  const _HomeCategory({
    required this.title,
    required this.color,
    required this.iconAsset,
    this.fontSize = 15,
  });

  final String title;
  final Color color;
  final String iconAsset;
  final double fontSize;
}
