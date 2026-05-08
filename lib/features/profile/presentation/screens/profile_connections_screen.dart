import 'package:flutter/material.dart';

import '../../../../core/widgets/resolved_image.dart';
import '../../../social/data/social_repository.dart';

enum ProfileConnectionsTab { following, followers, friends }

final class ProfileConnectionsScreenArgs {
  const ProfileConnectionsScreenArgs({
    this.initialTab = ProfileConnectionsTab.following,
    this.isCurrentUser = true,
    this.userId,
  });

  final ProfileConnectionsTab initialTab;
  final bool isCurrentUser;
  final int? userId;
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
  late Future<SocialConnectionsData> _future;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.args.initialTab;
    _future = _loadConnections(_selectedTab);
  }

  Future<SocialConnectionsData> _loadConnections(ProfileConnectionsTab tab) {
    return SocialRepository.instance.loadConnections(
      type: _socialType(tab),
      userId: widget.args.isCurrentUser ? null : widget.args.userId,
    );
  }

  Future<void> _refreshConnections() async {
    final future = _loadConnections(_selectedTab);
    setState(() {
      _future = future;
    });
    await future;
  }

  SocialConnectionType _socialType(ProfileConnectionsTab tab) {
    switch (tab) {
      case ProfileConnectionsTab.following:
        return SocialConnectionType.following;
      case ProfileConnectionsTab.followers:
        return SocialConnectionType.followers;
      case ProfileConnectionsTab.friends:
        return SocialConnectionType.friends;
    }
  }

  Future<void> _toggleFollow(SocialUserData user) async {
    if (user.relationship.isSelf) {
      return;
    }

    try {
      await SocialRepository.instance.toggleFollow(userId: user.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _future = _loadConnections(_selectedTab);
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
                          _future = _loadConnections(tab);
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<SocialConnectionsData>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: _activeBlue,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildRefreshableMessage(
                            _ConnectionsMessage(
                              message: 'تعذر تحميل البيانات',
                              actionLabel: 'إعادة المحاولة',
                              onActionTap: _refreshConnections,
                            ),
                          );
                        }

                        final users = snapshot.data?.users ?? const [];
                        if (users.isEmpty) {
                          return _buildRefreshableMessage(
                            const _ConnectionsMessage(message: 'لا يوجد محتوي'),
                          );
                        }

                        return RefreshIndicator(
                          color: _activeBlue,
                          onRefresh: _refreshConnections,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                            itemCount: users.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return _ConnectionUserCard(
                                user: user,
                                onFollowTap: () => _toggleFollow(user),
                              );
                            },
                          ),
                        );
                      },
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

  Widget _buildRefreshableMessage(Widget child) {
    return RefreshIndicator(
      color: _activeBlue,
      onRefresh: _refreshConnections,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.58,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ConnectionsMessage extends StatelessWidget {
  const _ConnectionsMessage({
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
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
          Text(
            message,
            style: const TextStyle(
              color: _ProfileConnectionsScreenState._emptyPink,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: _ProfileConnectionsScreenState._activeBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionUserCard extends StatelessWidget {
  const _ConnectionUserCard({required this.user, required this.onFollowTap});

  final SocialUserData user;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    final relationship = user.relationship;
    final buttonLabel = relationship.isSelf
        ? 'أنت'
        : relationship.isFriend
        ? 'أصدقاء'
        : relationship.isFollowing
        ? 'الغاء المتابعة'
        : relationship.isFollowedBy
        ? 'رد المتابعة'
        : 'متابعة';
    final filled = !relationship.isFollowing && !relationship.isFriend;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: ResolvedImage(
              path: user.avatarAsset,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _ProfileConnectionsScreenState._activeBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF6F879F),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: relationship.isSelf ? null : onFollowTap,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              height: 34,
              constraints: const BoxConstraints(minWidth: 88),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: filled
                    ? _ProfileConnectionsScreenState._activeBlue
                    : const Color(0xFFE7EEF6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: filled
                      ? Colors.white
                      : _ProfileConnectionsScreenState._activeBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
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
