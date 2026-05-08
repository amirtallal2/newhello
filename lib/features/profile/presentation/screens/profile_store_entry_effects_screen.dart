import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/profile_economy_repository.dart';
import 'profile_store_send_frame_screen.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileStoreEntryEffectsScreen extends StatefulWidget {
  const ProfileStoreEntryEffectsScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _secondaryBlue = Color(0xFF9DB2CE);

  @override
  State<ProfileStoreEntryEffectsScreen> createState() =>
      _ProfileStoreEntryEffectsScreenState();
}

class _ProfileStoreEntryEffectsScreenState
    extends State<ProfileStoreEntryEffectsScreen> {
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
        categoryKey: 'entry_effects',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = catalog.items;
      });
    } catch (_) {}
  }

  Future<void> _showPurchaseDialog(StoreItemData item) {
    var selectedDurationIndex = item.durations.indexWhere(
      (duration) => duration.days == item.defaultDurationDays,
    );
    if (selectedDurationIndex < 0) {
      selectedDurationIndex = 0;
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'profile-store-entry-effects-purchase-dialog',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final durations = item.durations;
            final selectedDuration = durations[selectedDurationIndex];
            final dialogIconAssetPath =
                item.dialogIconAssetPath ?? item.previewAssetPath;
            final dialogPreviewAssetPath =
                item.dialogPreviewAssetPath ?? item.previewAssetPath;
            return Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                    child: Container(color: const Color(0x4DB3A1A1)),
                  ),
                ),
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      key: const ValueKey('profile-store-entry-effects-dialog'),
                      width: 309,
                      padding: const EdgeInsets.fromLTRB(19, 20, 18, 23),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 50,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ResolvedImage(
                                      path: dialogIconAssetPath,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: ProfileStoreEntryEffectsScreen
                                          ._primaryBlue,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ResolvedImage(
                              path: dialogPreviewAssetPath,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            const SizedBox(height: 17),
                            Row(
                              children: [
                                Expanded(
                                  child: _EntryEffectDurationOptionButton(
                                    data:
                                        _EntryEffectPurchaseDurationData.fromDuration(
                                          durations[2],
                                        ),
                                    isSelected: selectedDurationIndex == 2,
                                    onTap: () {
                                      setDialogState(() {
                                        selectedDurationIndex = 2;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _EntryEffectDurationOptionButton(
                                    data:
                                        _EntryEffectPurchaseDurationData.fromDuration(
                                          durations[1],
                                        ),
                                    isSelected: selectedDurationIndex == 1,
                                    onTap: () {
                                      setDialogState(() {
                                        selectedDurationIndex = 1;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _EntryEffectDurationOptionButton(
                                    data:
                                        _EntryEffectPurchaseDurationData.fromDuration(
                                          durations[0],
                                        ),
                                    isSelected: selectedDurationIndex == 0,
                                    onTap: () {
                                      setDialogState(() {
                                        selectedDurationIndex = 0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 84,
                                child: _EntryEffectDurationOptionButton(
                                  data:
                                      _EntryEffectPurchaseDurationData.fromDuration(
                                        durations[3],
                                      ),
                                  isSelected: selectedDurationIndex == 3,
                                  onTap: () {
                                    setDialogState(() {
                                      selectedDurationIndex = 3;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'الاسعار : ${selectedDuration.price}',
                              style: const TextStyle(
                                color:
                                    ProfileStoreEntryEffectsScreen._primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 177,
                              height: 39,
                              child: ElevatedButton(
                                key: const ValueKey(
                                  'profile-store-entry-effects-dialog-buy',
                                ),
                                onPressed: () async {
                                  final navigator = Navigator.of(dialogContext);
                                  final messenger = ScaffoldMessenger.of(
                                    this.context,
                                  );
                                  try {
                                    await _economyRepository.purchaseStoreItem(
                                      itemId: item.id,
                                      durationDays: selectedDuration.days,
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    navigator.pop();
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
                                      SnackBar(content: Text(error.toString())),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      ProfileStoreEntryEffectsScreen
                                          ._primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  'شراء',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
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
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileStoreEntryEffectsScreen._surfaceGrey,
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
                      label: 'profile-store-entry-effects-back',
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
                            color: ProfileStoreEntryEffectsScreen._primaryBlue,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'الدخلات',
                    style: TextStyle(
                      color: ProfileStoreEntryEffectsScreen._primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: ProfileStoreEntryEffectsScreen._primaryBlue,
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
                              color:
                                  ProfileStoreEntryEffectsScreen._primaryBlue,
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
                                child: _EntryEffectStoreItemCard(
                                  index: index,
                                  item: _items[index],
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
                                  onBuyTap: () {
                                    _showPurchaseDialog(_items[index]);
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

class _EntryEffectStoreItemCard extends StatelessWidget {
  const _EntryEffectStoreItemCard({
    required this.index,
    required this.item,
    required this.onGiftTap,
    required this.onBuyTap,
  });

  final int index;
  final StoreItemData item;
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
                  color: ProfileStoreEntryEffectsScreen._primaryBlue,
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
                  color: ProfileStoreEntryEffectsScreen._primaryBlue,
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
                child: _EntryEffectActionButton(
                  label: 'ارسال',
                  backgroundColor:
                      ProfileStoreEntryEffectsScreen._secondaryBlue,
                  onTap: onGiftTap,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _EntryEffectActionButton(
                  buttonKey: ValueKey(
                    'profile-store-entry-effects-item-buy-$index',
                  ),
                  label: 'شراء',
                  backgroundColor: ProfileStoreEntryEffectsScreen._primaryBlue,
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

class _EntryEffectActionButton extends StatelessWidget {
  const _EntryEffectActionButton({
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

class _EntryEffectDurationOptionButton extends StatelessWidget {
  const _EntryEffectDurationOptionButton({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _EntryEffectPurchaseDurationData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mainColor = isSelected
        ? ProfileStoreEntryEffectsScreen._primaryBlue
        : ProfileStoreEntryEffectsScreen._secondaryBlue;
    final badgeColor = isSelected
        ? ProfileStoreEntryEffectsScreen._secondaryBlue
        : ProfileStoreEntryEffectsScreen._primaryBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      data.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 28,
                height: 10,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  data.discount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 5,
                    fontWeight: FontWeight.w500,
                    height: 1,
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

class _EntryEffectPurchaseDurationData {
  const _EntryEffectPurchaseDurationData({
    required this.label,
    required this.discount,
  });

  final String label;
  final String discount;

  factory _EntryEffectPurchaseDurationData.fromDuration(
    StoreDurationOptionData duration,
  ) {
    return _EntryEffectPurchaseDurationData(
      label: '${duration.days} ايام',
      discount: duration.discount,
    );
  }
}
