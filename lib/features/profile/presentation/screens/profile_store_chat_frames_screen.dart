import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/profile_economy_repository.dart';
import 'profile_store_send_frame_screen.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileStoreChatFramesScreen extends StatefulWidget {
  const ProfileStoreChatFramesScreen({super.key});

  @override
  State<ProfileStoreChatFramesScreen> createState() =>
      _ProfileStoreChatFramesScreenState();
}

class _ProfileStoreChatFramesScreenState
    extends State<ProfileStoreChatFramesScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _secondaryBlue = Color(0xFF9DB2CE);
  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;
  List<StoreItemData> _items = const <StoreItemData>[];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await _economyRepository.loadStoreCatalog(
        categoryKey: 'chat_frames',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = catalog.items;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGrey,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 40),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'profile-store-chat-frames-back',
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
                    'اطارات المحادثات',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: _primaryBlue,
                onRefresh: _loadCatalog,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(17, 10, 17, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 1, bottom: 11),
                          child: Text(
                            'جديد',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 20.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing) / 2;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 20,
                            children: List.generate(_items.length, (index) {
                              return SizedBox(
                                width: cardWidth,
                                child: _ChatFrameStoreItemCard(
                                  item: _items[index],
                                  index: index,
                                  onGiftTap: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.profileStoreSendFrame,
                                      arguments: ProfileStoreSendArgs(
                                        itemId: _items[index].id,
                                        itemName: _items[index].name,
                                        durationDays:
                                            _items[index].defaultDuration.days,
                                      ),
                                    );
                                  },
                                  onBuyTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await _economyRepository
                                          .purchaseStoreItem(
                                            itemId: _items[index].id,
                                            durationDays: _items[index]
                                                .defaultDuration
                                                .days,
                                          );
                                      if (!mounted) {
                                        return;
                                      }
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('تم شراء العنصر بنجاح'),
                                        ),
                                      );
                                    } catch (error) {
                                      if (!mounted) {
                                        return;
                                      }
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(error.toString()),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }),
                          );
                        },
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

class _ChatFrameStoreItemCard extends StatelessWidget {
  const _ChatFrameStoreItemCard({
    required this.item,
    required this.index,
    required this.onGiftTap,
    required this.onBuyTap,
  });

  final StoreItemData item;
  final int index;
  final VoidCallback onGiftTap;
  final VoidCallback onBuyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'معاينة',
                style: TextStyle(
                  color: _ProfileStoreChatFramesScreenState._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/profile_store_coin_icon.png',
                width: 18,
                height: 18,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 9),
              Text(
                '${item.defaultDuration.days} أيام',
                style: const TextStyle(
                  color: _ProfileStoreChatFramesScreenState._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResolvedImage(
            path: item.previewAssetPath,
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ChatFrameActionButton(
                  label: 'ارسال',
                  backgroundColor:
                      _ProfileStoreChatFramesScreenState._secondaryBlue,
                  onTap: onGiftTap,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _ChatFrameActionButton(
                  buttonKey: ValueKey(
                    'profile-store-chat-frames-item-buy-$index',
                  ),
                  label: 'شراء',
                  backgroundColor:
                      _ProfileStoreChatFramesScreenState._primaryBlue,
                  onTap: onBuyTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatFrameActionButton extends StatelessWidget {
  const _ChatFrameActionButton({
    this.buttonKey,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final Key? buttonKey;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}
