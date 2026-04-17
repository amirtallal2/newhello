import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../widgets/main_bottom_navigation.dart';

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

  static const List<_LivePosterData> _posters = [
    _LivePosterData(imageAsset: 'assets/images/home149_card1.png'),
    _LivePosterData(imageAsset: 'assets/images/home149_card2.png'),
    _LivePosterData(imageAsset: 'assets/images/home149_card3.png'),
    _LivePosterData(imageAsset: 'assets/images/home149_card4.png'),
    _LivePosterData(imageAsset: 'assets/images/home149_card7.png'),
    _LivePosterData(imageAsset: 'assets/images/home149_card8.png'),
  ];

  _LiveTopTab _selectedTab = _LiveTopTab.live;

  void _openLiveRoom(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.liveRoom);
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 60, 12, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LiveHeaderRow(
                          selectedTab: _selectedTab,
                          onTabSelected: (tab) {
                            setState(() {
                              _selectedTab = tab;
                            });
                          },
                          onSearchTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.bootstrap),
                          onNotificationTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.bootstrap),
                        ),
                        const SizedBox(height: 30),
                        const _LiveHeroBanner(),
                        const SizedBox(height: 35),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posters.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 29,
                                mainAxisSpacing: 15,
                                childAspectRatio: 158 / 145,
                              ),
                          itemBuilder: (context, index) {
                            return _LivePosterCard(
                              key: ValueKey('live-room-card-$index'),
                              data: _posters[index],
                              onTap: () => _openLiveRoom(context),
                            );
                          },
                        ),
                      ],
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
        const SizedBox(width: 15),
        _LiveNotificationButton(onTap: onNotificationTap),
        const Spacer(),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              _LiveTopTabButton(
                label: 'بث مباشر',
                width: 58,
                isActive: selectedTab == _LiveTopTab.live,
                onTap: () => onTabSelected(_LiveTopTab.live),
              ),
              const SizedBox(width: 30),
              _LiveTopTabButton(
                label: 'جديد',
                width: 34,
                isActive: selectedTab == _LiveTopTab.newest,
                onTap: () => onTabSelected(_LiveTopTab.newest),
              ),
              const SizedBox(width: 30),
              _LiveTopTabButton(
                label: 'اصدقاء',
                width: 47,
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/home149_banner.png',
            width: double.infinity,
            height: 134,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        const Positioned(
          top: 58,
          child: Text(
            'اهلآ بكم في اللايف الخاص بنـا',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
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

class _LivePosterCard extends StatelessWidget {
  const _LivePosterCard({super.key, required this.data, required this.onTap});

  final _LivePosterData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                data.imageAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF285F98), Color(0xFF3C90FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: const [
                      Center(
                        child: Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Text(
                          '22',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                right: 8,
                bottom: 8,
                child: Text(
                  'هاي عاملين ايه',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 5,
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
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
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

class _LivePosterData {
  const _LivePosterData({required this.imageAsset});

  final String imageAsset;
}
