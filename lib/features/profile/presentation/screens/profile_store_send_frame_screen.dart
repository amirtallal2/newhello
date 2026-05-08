import 'package:flutter/material.dart';

import '../../../../core/widgets/resolved_image.dart';
import '../../data/profile_economy_repository.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileStoreSendArgs {
  const ProfileStoreSendArgs({
    required this.itemId,
    required this.itemName,
    required this.durationDays,
  });

  final int itemId;
  final String itemName;
  final int durationDays;
}

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

  final TextEditingController _searchController = TextEditingController();
  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;
  List<StoreRecipientData> _friends = const <StoreRecipientData>[];

  int? _selectedFriendIndex;
  bool _didLoadInitialData = false;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialData) {
      return;
    }

    _didLoadInitialData = true;
    _loadFriends(_searchController.text);
  }

  Future<void> _loadFriends(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final friends = await _economyRepository.loadStoreRecipients(
        query: query,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _friends = friends;
        if (_selectedFriendIndex != null &&
            _selectedFriendIndex! >= _friends.length) {
          _selectedFriendIndex = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFriends() {
    return _loadFriends(_searchController.text);
  }

  Future<void> _submitSend() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final sendArgs = args is ProfileStoreSendArgs ? args : null;
    final selectedIndex = _selectedFriendIndex;

    if (sendArgs == null ||
        selectedIndex == null ||
        selectedIndex >= _friends.length) {
      return;
    }

    final recipient = _friends[selectedIndex];

    setState(() {
      _isSending = true;
    });

    try {
      await _economyRepository.sendStoreItem(
        itemId: sendArgs.itemId,
        durationDays: sendArgs.durationDays,
        recipientName: recipient.name,
        recipientUserId: recipient.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الإرسال بنجاح')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final sendArgs = args is ProfileStoreSendArgs ? args : null;
    final canSend =
        sendArgs != null &&
        _selectedFriendIndex != null &&
        !_isSending &&
        !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: _primaryBlue,
                onRefresh: _refreshFriends,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                    onChanged: _loadFriends,
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
                        if (_isLoading)
                          const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          SizedBox(
                            height: 180,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _refreshFriends,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_friends.isEmpty)
                          const SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(
                                'لا توجد نتائج',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
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
                        if (sendArgs != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'العنصر: ${sendArgs.itemName}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Center(
                          child: SizedBox(
                            width: 177,
                            height: 39,
                            child: ElevatedButton(
                              key: const ValueKey('profile-store-send-submit'),
                              onPressed: canSend ? _submitSend : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Text(
                                _isSending ? 'جارى الإرسال...' : 'ارسال الان',
                                style: const TextStyle(
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

  final StoreRecipientData friend;
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
                  ResolvedImage(
                    path: friend.avatarAssetPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                  if (friend.innerAvatarAssetPath != null)
                    Positioned(
                      top: 14,
                      child: ClipOval(
                        child: ResolvedImage(
                          path: friend.innerAvatarAssetPath!,
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
