import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/profile_economy_repository.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import 'profile_store_send_frame_screen.dart';

class ProfileStoreAristocracyScreen extends StatefulWidget {
  const ProfileStoreAristocracyScreen({super.key});

  @override
  State<ProfileStoreAristocracyScreen> createState() =>
      _ProfileStoreAristocracyScreenState();
}

class _ProfileStoreAristocracyScreenState
    extends State<ProfileStoreAristocracyScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _secondaryBlue = Color(0xFF9DB2CE);

  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;

  List<StoreItemData> _items = const <StoreItemData>[];
  bool _isLoading = true;
  String? _errorMessage;
  int? _busyItemId;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catalog = await _economyRepository.loadStoreCatalog(
        categoryKey: 'aristocracy',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = catalog.items;
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

  Future<void> _showPurchaseSheet(StoreItemData item) async {
    if (_busyItemId != null) {
      return;
    }

    final selectedDuration =
        await showModalBottomSheet<StoreDurationOptionData>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            final durations = item.durations;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7E5F6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: ResolvedImage(
                              path:
                                  item.dialogPreviewAssetPath ??
                                  item.previewAssetPath,
                              width: 58,
                              height: 58,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: durations
                            .map(
                              (duration) => SizedBox(
                                width:
                                    (MediaQuery.sizeOf(context).width - 50) / 2,
                                child: _AristocracyDurationButton(
                                  duration: duration,
                                  onTap: () {
                                    Navigator.of(context).pop(duration);
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

    if (selectedDuration == null) {
      return;
    }

    await _purchaseItem(item: item, duration: selectedDuration);
  }

  Future<void> _purchaseItem({
    required StoreItemData item,
    required StoreDurationOptionData duration,
  }) async {
    setState(() {
      _busyItemId = item.id;
    });

    try {
      await _economyRepository.purchaseStoreItem(
        itemId: item.id,
        durationDays: duration.days,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم شراء العنصر بنجاح')));
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
          _busyItemId = null;
        });
      }
    }
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
                      label: 'profile-store-aristocracy-back',
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
                    'استقراطيه',
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
                  child: Directionality(
                    textDirection: TextDirection.rtl,
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
                        if (_isLoading)
                          const SizedBox(
                            height: 220,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          _AristocracyMessage(
                            message: _errorMessage!,
                            onRetry: _loadCatalog,
                          )
                        else if (_items.isEmpty)
                          const _AristocracyMessage(
                            message: 'لا توجد عناصر في هذا القسم حتى الآن',
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 20.0;
                              final cardWidth =
                                  (constraints.maxWidth - spacing) / 2;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: 20,
                                children: List.generate(_items.length, (index) {
                                  final item = _items[index];
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _AristocracyStoreItemCard(
                                      item: item,
                                      index: index,
                                      isBusy: _busyItemId == item.id,
                                      onGiftTap: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.profileStoreSendFrame,
                                          arguments: ProfileStoreSendArgs(
                                            itemId: item.id,
                                            itemName: item.name,
                                            durationDays:
                                                item.defaultDuration.days,
                                          ),
                                        );
                                      },
                                      onBuyTap: () {
                                        _showPurchaseSheet(item);
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

class _AristocracyStoreItemCard extends StatelessWidget {
  const _AristocracyStoreItemCard({
    required this.item,
    required this.index,
    required this.isBusy,
    required this.onGiftTap,
    required this.onBuyTap,
  });

  final StoreItemData item;
  final int index;
  final bool isBusy;
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
                  color: _ProfileStoreAristocracyScreenState._primaryBlue,
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
                  color: _ProfileStoreAristocracyScreenState._primaryBlue,
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
                child: _AristocracyActionButton(
                  label: 'ارسال',
                  backgroundColor:
                      _ProfileStoreAristocracyScreenState._secondaryBlue,
                  onTap: onGiftTap,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _AristocracyActionButton(
                  buttonKey: ValueKey(
                    'profile-store-aristocracy-item-buy-$index',
                  ),
                  label: isBusy ? '...' : 'شراء',
                  backgroundColor:
                      _ProfileStoreAristocracyScreenState._primaryBlue,
                  onTap: isBusy ? () {} : onBuyTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AristocracyDurationButton extends StatelessWidget {
  const _AristocracyDurationButton({
    required this.duration,
    required this.onTap,
  });

  final StoreDurationOptionData duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD7E5F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${duration.days} أيام',
              style: const TextStyle(
                color: _ProfileStoreAristocracyScreenState._primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${duration.price} عملة',
              style: const TextStyle(
                color: Color(0xFF6F7F94),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (duration.discount.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                duration.discount,
                style: const TextStyle(
                  color: Color(0xFFE88102),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AristocracyActionButton extends StatelessWidget {
  const _AristocracyActionButton({
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

class _AristocracyMessage extends StatelessWidget {
  const _AristocracyMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileStoreAristocracyScreenState._primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _ProfileStoreAristocracyScreenState._primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
