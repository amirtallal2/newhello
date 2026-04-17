import 'package:flutter/material.dart';

enum ProfileConnectionsTab { following, followers, friends }

final class ProfileConnectionsScreenArgs {
  const ProfileConnectionsScreenArgs({
    this.initialTab = ProfileConnectionsTab.following,
    this.isCurrentUser = true,
  });

  final ProfileConnectionsTab initialTab;
  final bool isCurrentUser;
}

class ProfileConnectionsScreen extends StatefulWidget {
  const ProfileConnectionsScreen({
    super.key,
    this.args = const ProfileConnectionsScreenArgs(),
  });

  final ProfileConnectionsScreenArgs args;

  @override
  State<ProfileConnectionsScreen> createState() =>
      _ProfileConnectionsScreenState();
}

class _ProfileConnectionsScreenState extends State<ProfileConnectionsScreen> {
  static const Color _activeBlue = Color(0xFF285F98);
  static const Color _emptyPink = Color(0xFFFF637B);

  late ProfileConnectionsTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.args.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(
        widget.args.isCurrentUser
            ? 'profile-connections-current-user'
            : 'profile-connections-visitor',
      ),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/profile_connections_background.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  const SizedBox(height: 46),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            label: 'profile-connections-back',
                            button: true,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(19),
                              child: Container(
                                width: 38,
                                height: 37,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB4D1EF),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _activeBlue,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'الاتصال',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ConnectionsTabs(
                      selectedTab: _selectedTab,
                      onTabSelected: (tab) {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/profile_connections_empty_state.png',
                            width: 100,
                            height: 100,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'لا يوجد محتوي',
                            style: TextStyle(
                              color: _emptyPink,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionsTabs extends StatelessWidget {
  const _ConnectionsTabs({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final ProfileConnectionsTab selectedTab;
  final ValueChanged<ProfileConnectionsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ConnectionsTabButton(
                label: 'اتابع',
                tab: ProfileConnectionsTab.following,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
            ),
            Expanded(
              child: _ConnectionsTabButton(
                label: 'المتابعون',
                tab: ProfileConnectionsTab.followers,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
            ),
            Expanded(
              child: _ConnectionsTabButton(
                label: 'الأصدقاء',
                tab: ProfileConnectionsTab.friends,
                selectedTab: selectedTab,
                onTap: onTabSelected,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          color: const Color(0xFFF0F0F0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    key: const ValueKey('profile-connections-active-following'),
                    duration: const Duration(milliseconds: 180),
                    width: selectedTab == ProfileConnectionsTab.following
                        ? 27
                        : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _ProfileConnectionsScreenState._activeBlue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    key: const ValueKey('profile-connections-active-followers'),
                    duration: const Duration(milliseconds: 180),
                    width: selectedTab == ProfileConnectionsTab.followers
                        ? 59
                        : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _ProfileConnectionsScreenState._activeBlue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    key: const ValueKey('profile-connections-active-friends'),
                    duration: const Duration(milliseconds: 180),
                    width: selectedTab == ProfileConnectionsTab.friends
                        ? 27
                        : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _ProfileConnectionsScreenState._activeBlue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectionsTabButton extends StatelessWidget {
  const _ConnectionsTabButton({
    required this.label,
    required this.tab,
    required this.selectedTab,
    required this.onTap,
  });

  final String label;
  final ProfileConnectionsTab tab;
  final ProfileConnectionsTab selectedTab;
  final ValueChanged<ProfileConnectionsTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-connections-tab-$label',
      button: true,
      child: InkWell(
        onTap: () => onTap(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
