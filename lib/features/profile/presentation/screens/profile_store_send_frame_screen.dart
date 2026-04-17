import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileStoreSendFrameScreen extends StatefulWidget {
  const ProfileStoreSendFrameScreen({super.key});

  @override
  State<ProfileStoreSendFrameScreen> createState() =>
      _ProfileStoreSendFrameScreenState();
}

class _ProfileStoreSendFrameScreenState
    extends State<ProfileStoreSendFrameScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _searchSurface = Color(0xFFF8F9FE);

  final TextEditingController _searchController = TextEditingController(
    text: 'Mo',
  );

  static const List<_FriendEntryData> _friends = [
    _FriendEntryData(
      name: 'Yara Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara.png',
    ),
    _FriendEntryData(
      name: 'Nona Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_nona_frame.png',
      innerAvatarAssetPath:
          'assets/images/profile_store_friend_nona_avatar.png',
    ),
    _FriendEntryData(
      name: 'Mohamed Ahmed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara_alt.png',
    ),
    _FriendEntryData(
      name: 'Yara Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara.png',
    ),
    _FriendEntryData(
      name: 'Nona Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_nona_frame.png',
      innerAvatarAssetPath:
          'assets/images/profile_store_friend_nona_avatar.png',
    ),
    _FriendEntryData(
      name: 'Mohamed Ahmed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara_alt.png',
    ),
    _FriendEntryData(
      name: 'Yara Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara.png',
    ),
    _FriendEntryData(
      name: 'Nona Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_nona_frame.png',
      innerAvatarAssetPath:
          'assets/images/profile_store_friend_nona_avatar.png',
    ),
    _FriendEntryData(
      name: 'Mohamed Ahmed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara_alt.png',
    ),
  ];

  int? _selectedFriendIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 46, 16, 24),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              label: 'profile-store-send-back',
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
                                    color: _primaryBlue,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'اصدقائي',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _searchSurface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.search,
                                color: Color(0xFF2F3036),
                                size: 16,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  key: const ValueKey(
                                    'profile-store-send-search',
                                  ),
                                  controller: _searchController,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF1F2024),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'احدث الدردشات ',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _friends.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 28,
                              crossAxisSpacing: 34,
                              childAspectRatio: 80 / 104,
                            ),
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return _FriendGridItem(
                            friend: friend,
                            isSelected: _selectedFriendIndex == index,
                            onTap: () {
                              setState(() {
                                _selectedFriendIndex = index;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: SizedBox(
                          width: 177,
                          height: 39,
                          child: ElevatedButton(
                            key: const ValueKey('profile-store-send-submit'),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'ارسال الان',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.profile,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendGridItem extends StatelessWidget {
  const _FriendGridItem({
    required this.friend,
    required this.isSelected,
    required this.onTap,
  });

  final _FriendEntryData friend;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-store-send-friend-${friend.name}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    friend.avatarAssetPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                  if (friend.innerAvatarAssetPath != null)
                    Positioned(
                      top: 14,
                      child: ClipOval(
                        child: Image.asset(
                          friend.innerAvatarAssetPath!,
                          width: 48,
                          height: 51,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  if (isSelected)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _ProfileStoreSendFrameScreenState._primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              friend.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileStoreSendFrameScreenState._primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendEntryData {
  const _FriendEntryData({
    required this.name,
    required this.avatarAssetPath,
    this.innerAvatarAssetPath,
  });

  final String name;
  final String avatarAssetPath;
  final String? innerAvatarAssetPath;
}
