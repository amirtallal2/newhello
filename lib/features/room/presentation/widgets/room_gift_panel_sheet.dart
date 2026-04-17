import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/room_gift_repository.dart';
import '../controllers/room_session_controller.dart';

class RoomGiftPanelSheet extends StatefulWidget {
  const RoomGiftPanelSheet({super.key});

  @override
  State<RoomGiftPanelSheet> createState() => _RoomGiftPanelSheetState();
}

class _RoomGiftPanelSheetState extends State<RoomGiftPanelSheet> {
  int? _selectedGiftIndex;
  int _selectedRecipientIndex = 0;
  int _selectedQuantity = 100;
  bool _isQuantityPickerOpen = false;
  bool _isRecipientSelectorExpanded = false;
  bool _isLoading = true;
  bool _isSending = false;
  _GiftRecipientMode _recipientMode = _GiftRecipientMode.roomUsers;
  late final FixedExtentScrollController _quantityController;
  RoomGiftPanelData _panelData = const RoomGiftPanelData(
    walletCoinsBalance: 1235,
    walletDiamondsBalance: 5,
    isGuest: false,
    gifts: <RoomGiftItemData>[
      RoomGiftItemData(
        id: 1,
        name: 'الهدية الصغيرة',
        category: 'الهداية عادية',
        assetPath: 'assets/images/room_gift_1.png',
        priceCoins: 10,
      ),
      RoomGiftItemData(
        id: 2,
        name: 'الهدية الصغيرة',
        category: 'الهداية عادية',
        assetPath: 'assets/images/room_gift_2.png',
        priceCoins: 10,
      ),
      RoomGiftItemData(
        id: 3,
        name: 'الهدية الصغيرة',
        category: 'الهداية عادية',
        assetPath: 'assets/images/room_gift_3.png',
        priceCoins: 10,
      ),
      RoomGiftItemData(
        id: 4,
        name: 'الهدية الصغيرة',
        category: 'الهداية عادية',
        assetPath: 'assets/images/room_gift_4.png',
        priceCoins: 10,
      ),
      RoomGiftItemData(
        id: 5,
        name: 'الهدية الصغيرة',
        category: 'VIP',
        assetPath: 'assets/images/room_gift_5.png',
        priceCoins: 20,
      ),
      RoomGiftItemData(
        id: 6,
        name: 'الهدية الصغيرة',
        category: 'VIP',
        assetPath: 'assets/images/room_gift_6.png',
        priceCoins: 25,
      ),
      RoomGiftItemData(
        id: 7,
        name: 'الهدية الصغيرة',
        category: 'المحظوظ',
        assetPath: 'assets/images/room_gift_7.png',
        priceCoins: 30,
      ),
      RoomGiftItemData(
        id: 8,
        name: 'الهدية الصغيرة',
        category: 'متحرك',
        assetPath: 'assets/images/room_gift_8.png',
        priceCoins: 40,
      ),
    ],
  );

  static const List<String> _tabs = [
    'VIP',
    'المحظوظ',
    'متحرك',
    'اعلام',
    'الهداية عادية',
  ];

  @override
  void initState() {
    super.initState();
    _quantityController = FixedExtentScrollController(
      initialItem: _selectedQuantity - 1,
    );
    _loadPanel();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  bool get _hasSelectedGift => _selectedGiftIndex != null;

  Future<void> _loadPanel() async {
    try {
      final panelData = await RoomGiftRepository.instance.loadGiftPanel(
        roomId: RoomSessionController.instance.activeRoomId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _panelData = panelData;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleGiftTap(int index) {
    setState(() {
      _selectedGiftIndex = index;
      _isQuantityPickerOpen = false;
    });
  }

  void _handleRecipientTap(int index) {
    setState(() {
      _selectedRecipientIndex = index;
    });
  }

  void _expandRecipientSelector() {
    setState(() {
      _isRecipientSelectorExpanded = true;
    });
  }

  void _collapseRecipientSelector() {
    setState(() {
      _isRecipientSelectorExpanded = false;
    });
  }

  void _toggleQuantityPicker() {
    if (!_hasSelectedGift) {
      return;
    }

    if (!_isQuantityPickerOpen) {
      _quantityController.jumpToItem(_selectedQuantity - 1);
    }

    setState(() {
      _isQuantityPickerOpen = !_isQuantityPickerOpen;
    });
  }

  Future<void> _sendSelectedGift() async {
    final selectedGiftIndex = _selectedGiftIndex;
    if (selectedGiftIndex == null || selectedGiftIndex >= _panelData.gifts.length) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final updatedPanel = await RoomGiftRepository.instance.sendGift(
        roomId: RoomSessionController.instance.activeRoomId,
        giftId: _panelData.gifts[selectedGiftIndex].id,
        quantity: _selectedQuantity,
        recipientMode: _recipientMode == _GiftRecipientMode.roomUsers
            ? 'room_users'
            : 'selected_user',
        recipientSlot: _recipientMode == _GiftRecipientMode.selectedUser
            ? (_selectedRecipientIndex == 0 ? 1 : _selectedRecipientIndex)
            : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _panelData = updatedPanel;
        _isQuantityPickerOpen = false;
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ارسال الهدية')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'room-gift-panel',
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: const Color(0x05000000)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 294,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GiftPanelHeader(
                            tabs: _tabs,
                            selectedTab: _tabs.last,
                            onCloseTap: () => Navigator.of(context).pop(),
                          ),
                          SizedBox(
                            height: _isRecipientSelectorExpanded ? 24 : 12,
                          ),
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF285F98),
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_isQuantityPickerOpen) ...[
                                        _GiftQuantityRail(
                                          controller: _quantityController,
                                          selectedQuantity: _selectedQuantity,
                                          onSelectedQuantityChanged: (
                                            quantity,
                                          ) {
                                            setState(() {
                                              _selectedQuantity = quantity;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 18),
                                      ],
                                      Expanded(
                                        child: GridView.builder(
                                          padding: EdgeInsets.zero,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _panelData.gifts.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                                mainAxisSpacing: 12,
                                                crossAxisSpacing: 18,
                                                childAspectRatio: 0.63,
                                              ),
                                          itemBuilder: (context, index) {
                                            return _GiftItemCard(
                                              semanticLabel:
                                                  'room-gift-item-$index',
                                              gift: _panelData.gifts[index],
                                              isSelected:
                                                  index == _selectedGiftIndex,
                                              onTap: () => _handleGiftTap(index),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 8),
                          _GiftPanelFooter(
                            showQuantityTrigger: _hasSelectedGift,
                            selectedQuantity: _selectedQuantity,
                            isQuantityPickerOpen: _isQuantityPickerOpen,
                            onQuantityTap: _toggleQuantityPicker,
                            walletBalance: _panelData.walletCoinsBalance,
                            onSendTap: _sendSelectedGift,
                            isSendEnabled:
                                _hasSelectedGift && !_isLoading && !_isSending,
                            isSending: _isSending,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isRecipientSelectorExpanded) ...[
                    Positioned(
                      top: -49,
                      left: 18,
                      right: 18,
                      child: _ExpandedRecipientsStrip(
                        selectedIndex: _selectedRecipientIndex,
                        onRecipientTap: _handleRecipientTap,
                        onCollapseTap: _collapseRecipientSelector,
                      ),
                    ),
                    Positioned(
                      top: -7,
                      left: 18,
                      child: _RecipientTargetModeCard(
                        selectedMode: _recipientMode,
                        onModeSelected: (mode) {
                          setState(() {
                            _recipientMode = mode;
                          });
                        },
                      ),
                    ),
                  ] else
                    Positioned(
                      top: -47,
                      left: 23,
                      right: 64,
                      child: _RecipientsStrip(
                        selectedIndex: _selectedRecipientIndex,
                        onTap: _handleRecipientTap,
                        onExpandTap: _expandRecipientSelector,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showRoomGiftPanelSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-gift-panel',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return const RoomGiftPanelSheet();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

class _GiftPanelHeader extends StatelessWidget {
  const _GiftPanelHeader({
    required this.tabs,
    required this.selectedTab,
    required this.onCloseTap,
  });

  final List<String> tabs;
  final String selectedTab;
  final VoidCallback onCloseTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          InkWell(
            onTap: onCloseTap,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Text(
                'x',
                style: TextStyle(
                  color: Color(0xFFEA4335),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                reverse: true,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: tabs.reversed.map((tab) {
                    final isSelected = tab == selectedTab;
                    return Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tab,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF285F98)
                                  : const Color(0xFF9DB2CE),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: isSelected ? 76 : 0,
                            height: 1,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF285F98)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientsStrip extends StatelessWidget {
  const _RecipientsStrip({
    required this.selectedIndex,
    required this.onTap,
    required this.onExpandTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onExpandTap;

  @override
  Widget build(BuildContext context) {
    const recipients = [6, 5, 4, 3, 2, 1];

    return Semantics(
      label: 'room-gift-recipients-strip',
      button: true,
      child: GestureDetector(
        key: const ValueKey('room-gift-recipients-strip'),
        onTap: onExpandTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 33,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  onTap(0);
                  onExpandTap();
                },
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: Color(0xFF285F98),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 33,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: recipients.asMap().entries.map((entry) {
                      final visualIndex = entry.key + 1;
                      final badgeNumber = entry.value;
                      return GestureDetector(
                        onTap: () {
                          onTap(visualIndex);
                          onExpandTap();
                        },
                        child: _RecipientAvatar(
                          badgeNumber: badgeNumber,
                          selected: selectedIndex == visualIndex,
                        ),
                      );
                    }).toList(),
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

class _ExpandedRecipientsStrip extends StatelessWidget {
  const _ExpandedRecipientsStrip({
    required this.selectedIndex,
    required this.onRecipientTap,
    required this.onCollapseTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onRecipientTap;
  final VoidCallback onCollapseTap;

  @override
  Widget build(BuildContext context) {
    const recipients = [1, 5, 2, 4, 6, 9];

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('room-gift-recipients-collapse'),
            onTap: onCollapseTap,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: Icon(
                Icons.expand_more_rounded,
                color: Color(0xFF285F98),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: recipients.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => onRecipientTap(entry.key),
                  child: _RecipientAvatar(
                    badgeNumber: entry.value,
                    selected: selectedIndex == entry.key,
                    size: 30,
                    avatarSize: 24,
                    badgeSize: 10,
                    badgeFontSize: 6,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientAvatar extends StatelessWidget {
  const _RecipientAvatar({
    required this.badgeNumber,
    required this.selected,
    this.size = 28,
    this.avatarSize = 24,
    this.badgeSize = 11,
    this.badgeFontSize = 6,
  });

  final int badgeNumber;
  final bool selected;
  final double size;
  final double avatarSize;
  final double badgeSize;
  final double badgeFontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: const Color(0xFF285F98), width: 1.2)
                  : null,
              image: const DecorationImage(
                image: AssetImage('assets/images/profile_avatar.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -4,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: const BoxDecoration(
                color: Color(0xFF285F98),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: badgeFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientTargetModeCard extends StatelessWidget {
  const _RecipientTargetModeCard({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final _GiftRecipientMode selectedMode;
  final ValueChanged<_GiftRecipientMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('room-gift-recipient-mode-card'),
      width: 175,
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD2DFF2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RecipientModeOption(
            label: 'جميع المستخدمين الغرفة',
            isSelected: selectedMode == _GiftRecipientMode.roomUsers,
            onTap: () => onModeSelected(_GiftRecipientMode.roomUsers),
          ),
          _RecipientModeOption(
            label: 'المستخدم المحدد',
            isSelected: selectedMode == _GiftRecipientMode.selectedUser,
            onTap: () => onModeSelected(_GiftRecipientMode.selectedUser),
          ),
        ],
      ),
    );
  }
}

class _RecipientModeOption extends StatelessWidget {
  const _RecipientModeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF285F98),
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF285F98), Color(0xFF6395C7)],
                    )
                  : null,
              color: isSelected ? null : const Color(0x809DB2CE),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftQuantityRail extends StatelessWidget {
  const _GiftQuantityRail({
    required this.controller,
    required this.selectedQuantity,
    required this.onSelectedQuantityChanged,
  });

  final FixedExtentScrollController controller;
  final int selectedQuantity;
  final ValueChanged<int> onSelectedQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'room-gift-quantity-picker',
      child: SizedBox(
        key: const ValueKey('room-gift-quantity-picker'),
        width: 44,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(color: const Color(0xFF285F98)),
              ListWheelScrollView.useDelegate(
                controller: controller,
                physics: const FixedExtentScrollPhysics(),
                itemExtent: 18,
                perspective: 0.003,
                diameterRatio: 1000,
                squeeze: 1,
                onSelectedItemChanged: (index) {
                  onSelectedQuantityChanged(index + 1);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 999,
                  builder: (context, index) {
                    final quantity = index + 1;
                    final isSelected = quantity == selectedQuantity;
                    return Center(
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSelected ? 7 : 5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(height: 22, color: const Color(0x80C3C3CE)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftItemCard extends StatelessWidget {
  const _GiftItemCard({
    required this.semanticLabel,
    required this.gift,
    required this.isSelected,
    required this.onTap,
  });

  final String semanticLabel;
  final RoomGiftItemData gift;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        key: ValueKey(semanticLabel),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: const Color(0xFFC9C9C9), width: 1)
                : null,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Column(
            children: [
              Image.asset(
                gift.assetPath,
                width: 50,
                height: 50,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 4),
              Text(
                gift.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF285F98),
                  shadows: [
                    Shadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${gift.priceCoins}',
                    style: const TextStyle(
                      color: Color(0xFF285F98),
                      shadows: [
                        Shadow(
                          color: Color(0x40000000),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Image.asset(
                    'assets/images/room_coin_small_icon.png',
                    width: 10,
                    height: 10,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
              const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftPanelFooter extends StatelessWidget {
  const _GiftPanelFooter({
    required this.showQuantityTrigger,
    required this.selectedQuantity,
    required this.isQuantityPickerOpen,
    required this.onQuantityTap,
    required this.walletBalance,
    required this.onSendTap,
    required this.isSendEnabled,
    required this.isSending,
  });

  final bool showQuantityTrigger;
  final int selectedQuantity;
  final bool isQuantityPickerOpen;
  final VoidCallback onQuantityTap;
  final int walletBalance;
  final VoidCallback onSendTap;
  final bool isSendEnabled;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showQuantityTrigger)
          Semantics(
            label: 'room-gift-quantity-trigger',
            button: true,
            child: GestureDetector(
              key: const ValueKey('room-gift-quantity-trigger'),
              onTap: onQuantityTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 80,
                height: 23,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 23,
                        decoration: const BoxDecoration(
                          color: Color(0xFF285F98),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/room_gift_inventory_icon.png',
                          width: 15,
                          height: 15,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 23,
                        decoration: const BoxDecoration(
                          color: Color(0xFF285F98),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                '$selectedQuantity',
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x40000000),
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              isQuantityPickerOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 80),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSendEnabled || isSending) ...[
              Semantics(
                label: 'room-gift-send',
                button: true,
                child: GestureDetector(
                  key: const ValueKey('room-gift-send'),
                  onTap: isSending ? null : onSendTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 64,
                    height: 23,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F9254),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: isSending
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ارسال',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 85,
              height: 23,
              decoration: BoxDecoration(
                color: const Color(0xFF285F98),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$walletBalance \$',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Color(0x40000000),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    'assets/images/room_coin_large_icon.png',
                    width: 15,
                    height: 15,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _GiftRecipientMode { roomUsers, selectedUser }
