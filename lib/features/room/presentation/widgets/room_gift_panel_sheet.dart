import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/room_gift_repository.dart';
import '../controllers/room_session_controller.dart';

class RoomGiftPanelSheet extends StatefulWidget {
  const RoomGiftPanelSheet({super.key});

  @override
  State<RoomGiftPanelSheet> createState() => _RoomGiftPanelSheetState();
}

class _RoomGiftPanelSheetState extends State<RoomGiftPanelSheet> {
  int? _selectedGiftId;
  int _selectedRecipientIndex = 0;
  int _selectedQuantity = 1;
  bool _isQuantityPickerOpen = false;
  bool _isRecipientSelectorExpanded = false;
  bool _isLoading = true;
  bool _isSending = false;
  RoomGiftItemData? _activeGiftEffect;
  int _activeGiftQuantity = 1;
  Timer? _giftEffectTimer;
  final AudioPlayer _giftAudioPlayer = AudioPlayer();
  final Set<String> _preloadedGiftVisualPaths = <String>{};
  String? _preparedGiftSoundPath;
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
    'الكل',
    'VIP',
    'المحظوظ',
    'متحرك',
    'اعلام',
    'الهداية عادية',
  ];
  String _selectedTab = _tabs.first;

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
    _giftEffectTimer?.cancel();
    unawaited(_giftAudioPlayer.dispose());
    _quantityController.dispose();
    super.dispose();
  }

  bool get _hasSelectedGift => _selectedGiftId != null;

  List<RoomGiftItemData> get _visibleGifts {
    if (_selectedTab == 'الكل') {
      return _panelData.gifts;
    }

    return _panelData.gifts
        .where((gift) => gift.category.trim() == _selectedTab)
        .toList();
  }

  RoomGiftItemData? get _selectedGift {
    final selectedGiftId = _selectedGiftId;
    if (selectedGiftId == null) {
      return null;
    }

    for (final gift in _panelData.gifts) {
      if (gift.id == selectedGiftId) {
        return gift;
      }
    }

    return null;
  }

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
      _precachePanelGifts(panelData.gifts);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleTabTap(String tab) {
    setState(() {
      _selectedTab = tab;
      _selectedGiftId = null;
      _isQuantityPickerOpen = false;
    });
  }

  void _handleGiftTap(RoomGiftItemData gift) {
    _warmGiftMedia(gift);
    setState(() {
      _selectedGiftId = gift.id;
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

  void _openWallet() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushNamed(AppRoutes.profileWallet);
      }
    });
  }

  Future<void> _sendSelectedGift() async {
    final selectedGift = _selectedGift;
    if (selectedGift == null) {
      return;
    }
    _warmGiftMedia(selectedGift);

    setState(() {
      _isSending = true;
    });

    try {
      final updatedPanel = await RoomGiftRepository.instance.sendGift(
        roomId: RoomSessionController.instance.activeRoomId,
        giftId: selectedGift.id,
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
      _showGiftEffect(selectedGift, quantity: _selectedQuantity);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم ارسال الهدية')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _showGiftEffect(RoomGiftItemData gift, {int quantity = 1}) {
    _giftEffectTimer?.cancel();
    _warmGiftMedia(gift);
    setState(() {
      _activeGiftEffect = gift;
      _activeGiftQuantity = quantity;
    });
    unawaited(_playGiftSound(gift.soundPath));

    _giftEffectTimer = Timer(
      Duration(milliseconds: gift.effectDurationMs.clamp(600, 8000).toInt()),
      () {
        if (!mounted || _activeGiftEffect?.id != gift.id) {
          return;
        }
        setState(() {
          _activeGiftEffect = null;
        });
      },
    );
  }

  Future<void> _playGiftSound(String soundPath) async {
    final path = soundPath.trim();
    if (path.isEmpty) {
      return;
    }

    try {
      if (_preparedGiftSoundPath == path) {
        await _giftAudioPlayer.seek(Duration.zero);
        await _giftAudioPlayer.resume();
        return;
      }

      await _giftAudioPlayer.stop();
      if (path.startsWith('assets/')) {
        await _giftAudioPlayer.play(
          AssetSource(path.replaceFirst(RegExp(r'^assets/'), '')),
        );
      } else {
        await _giftAudioPlayer.play(UrlSource(resolveMediaUrl(path)));
      }
      _preparedGiftSoundPath = path;
    } catch (_) {}
  }

  void _precachePanelGifts(List<RoomGiftItemData> gifts) {
    for (final gift in gifts) {
      _warmGiftMedia(gift, prepareSound: false);
    }
  }

  void _warmGiftMedia(RoomGiftItemData gift, {bool prepareSound = true}) {
    _precacheGiftVisual(gift.assetPath);
    _precacheGiftVisual(gift.effectAssetPath);

    if (prepareSound) {
      unawaited(_prepareGiftSound(gift.soundPath));
    }
  }

  void _precacheGiftVisual(String path) {
    final resolvedPath = path.trim();
    if (resolvedPath.isEmpty || !_preloadedGiftVisualPaths.add(resolvedPath)) {
      return;
    }

    unawaited(precacheResolvedImage(context, resolvedPath));
  }

  Future<void> _prepareGiftSound(String soundPath) async {
    final path = soundPath.trim();
    if (path.isEmpty || _preparedGiftSoundPath == path) {
      return;
    }

    try {
      if (path.startsWith('assets/')) {
        await _giftAudioPlayer.setSource(
          AssetSource(path.replaceFirst(RegExp(r'^assets/'), '')),
        );
      } else {
        await _giftAudioPlayer.setSource(UrlSource(resolveMediaUrl(path)));
      }
      _preparedGiftSoundPath = path;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final panelHeight = math
        .min(screenSize.height - 64, math.max(340.0, screenSize.height * 0.54))
        .toDouble();
    final horizontalPadding = screenSize.width < 360 ? 14.0 : 20.0;
    final visibleGifts = _visibleGifts;

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
                    height: panelHeight,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GiftPanelHeader(
                            tabs: _tabs,
                            selectedTab: _selectedTab,
                            onTabTap: _handleTabTap,
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
                                          onSelectedQuantityChanged:
                                              (quantity) {
                                                setState(() {
                                                  _selectedQuantity = quantity;
                                                });
                                              },
                                        ),
                                        const SizedBox(width: 18),
                                      ],
                                      Expanded(
                                        child: visibleGifts.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'لا توجد هدايا في هذا القسم',
                                                  style: TextStyle(
                                                    color: Color(0xFF285F98),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              )
                                            : LayoutBuilder(
                                                builder: (context, constraints) {
                                                  final crossAxisCount = math
                                                      .max(
                                                        3,
                                                        math.min(
                                                          5,
                                                          (constraints.maxWidth /
                                                                  82)
                                                              .floor(),
                                                        ),
                                                      )
                                                      .toInt();
                                                  return GridView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount:
                                                        visibleGifts.length,
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount:
                                                              crossAxisCount,
                                                          mainAxisSpacing: 12,
                                                          crossAxisSpacing: 12,
                                                          childAspectRatio:
                                                              0.64,
                                                        ),
                                                    itemBuilder: (context, index) {
                                                      final gift =
                                                          visibleGifts[index];
                                                      return _GiftItemCard(
                                                        semanticLabel:
                                                            'room-gift-item-$index',
                                                        gift: gift,
                                                        isSelected:
                                                            gift.id ==
                                                            _selectedGiftId,
                                                        onTap: () =>
                                                            _handleGiftTap(
                                                              gift,
                                                            ),
                                                      );
                                                    },
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
                            onWalletTap: _openWallet,
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
            if (_activeGiftEffect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _RoomGiftEffectOverlay(
                    gift: _activeGiftEffect!,
                    quantity: _activeGiftQuantity,
                  ),
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
    barrierLabel: 'room-gift-panel-dismiss',
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

class _RoomGiftEffectOverlay extends StatelessWidget {
  const _RoomGiftEffectOverlay({required this.gift, required this.quantity});

  final RoomGiftItemData gift;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: 18,
          left: 72,
          bottom: 330,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('room-gift-toast-${gift.id}-$quantity'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset((1 - value) * 70, 0),
                  child: child,
                ),
              );
            },
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: 52,
                padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 10, 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xE61B2431), Color(0xCC285F98)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تم إرسال ${gift.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: ResolvedImage(
                        path: gift.assetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('room-gift-burst-${gift.id}-$quantity'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 880),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final scale =
                  0.72 + (math.sin(value * math.pi) * 0.2) + value * 0.1;
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -16 * value),
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: SizedBox(
              width: 252,
              height: 252,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _RoomGiftParticle(angle: -2.4, distance: 106, size: 9),
                  const _RoomGiftParticle(angle: -1.3, distance: 116, size: 12),
                  const _RoomGiftParticle(angle: -0.3, distance: 108, size: 8),
                  const _RoomGiftParticle(angle: 0.8, distance: 112, size: 10),
                  const _RoomGiftParticle(angle: 2.1, distance: 118, size: 7),
                  Container(
                    width: 194,
                    height: 194,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 164,
                    height: 164,
                    child: ResolvedImage(
                      path: gift.effectAssetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    bottom: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xF2FFCE37),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Text(
                          'x$quantity',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: Color(0xFF1C2530),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
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
      ],
    );
  }
}

class _RoomGiftParticle extends StatelessWidget {
  const _RoomGiftParticle({
    required this.angle,
    required this.distance,
    required this.size,
  });

  final double angle;
  final double distance;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 920),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: (1 - value * 0.72).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              math.cos(angle) * distance * value,
              math.sin(angle) * distance * value,
            ),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD646),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD646).withValues(alpha: 0.55),
              blurRadius: 14,
            ),
          ],
        ),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}

class _GiftPanelHeader extends StatelessWidget {
  const _GiftPanelHeader({
    required this.tabs,
    required this.selectedTab,
    required this.onTabTap,
    required this.onCloseTap,
  });

  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onTabTap;
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
                      padding: const EdgeInsets.only(left: 12),
                      child: GestureDetector(
                        onTap: () => onTabTap(tab),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
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
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: isSelected ? 48 : 0,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF285F98)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ],
                          ),
                        ),
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
        width: 58,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(color: const Color(0xFF285F98)),
              ListWheelScrollView.useDelegate(
                controller: controller,
                physics: const FixedExtentScrollPhysics(),
                itemExtent: 28,
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
                          fontSize: isSelected ? 13 : 10,
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
                  child: Container(height: 30, color: const Color(0x80C3C3CE)),
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
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
          child: Column(
            children: [
              ResolvedImage(
                path: gift.assetPath,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 3),
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
                  fontSize: 11,
                  height: 1.05,
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
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Image.asset(
                    'assets/images/room_coin_small_icon.png',
                    width: 13,
                    height: 13,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
              if (gift.isAnimated || gift.hasSound)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (gift.isAnimated)
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF285F98),
                        size: 10,
                      ),
                    if (gift.hasSound)
                      const Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFF285F98),
                        size: 10,
                      ),
                  ],
                ),
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
    required this.onWalletTap,
    required this.isSendEnabled,
    required this.isSending,
  });

  final bool showQuantityTrigger;
  final int selectedQuantity;
  final bool isQuantityPickerOpen;
  final VoidCallback onQuantityTap;
  final int walletBalance;
  final VoidCallback onSendTap;
  final VoidCallback onWalletTap;
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
                width: 96,
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF285F98),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/room_gift_inventory_icon.png',
                          width: 20,
                          height: 20,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
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
                                  fontSize: 13,
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
                              size: 18,
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
          const SizedBox(width: 96),
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
                    width: 92,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F9254),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ارسال',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Semantics(
              label: 'room-gift-wallet',
              button: true,
              child: GestureDetector(
                key: const ValueKey('room-gift-wallet'),
                onTap: onWalletTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 132,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF285F98),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '$walletBalance \$',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                      const SizedBox(width: 6),
                      Image.asset(
                        'assets/images/room_coin_large_icon.png',
                        width: 20,
                        height: 20,
                        filterQuality: FilterQuality.high,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _GiftRecipientMode { roomUsers, selectedUser }
