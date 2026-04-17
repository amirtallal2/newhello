import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _accentRed = Color(0xFFF01F38);
  static const Color _overlay = Color(0x80232222);

  static const List<_LiveRoomComment> _comments = [
    _LiveRoomComment(
      name: 'Mohamed Ahmed',
      message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
    ),
    _LiveRoomComment(
      name: 'Mohamed Ahmed',
      message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
    ),
    _LiveRoomComment(
      name: 'Mohamed Ahmed',
      message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
    ),
    _LiveRoomComment(
      name: 'Mohamed Ahmed',
      message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
    ),
    _LiveRoomComment(
      name: 'Mohamed Ahmed',
      message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
    ),
    _LiveRoomComment(
      name: 'Mohamed Ahmed',
      message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
    ),
  ];

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  bool _showRoomTools = false;
  bool _showEffectControls = false;
  bool _showEffectSettingsPanel = false;
  bool _showViewersPanel = false;
  bool _showContributionPanel = false;
  bool _showPkPanel = false;
  bool _showPkLiveSettingsPanel = false;
  String _pkTalkPermission = 'عند الطلب';
  String _pkPartyInvitePermission = 'عند الطلب';
  String _pkVoiceRoomInvitePermission = 'عند الطلب';
  String _pkChatPermission = 'عند الطلب';
  String _pkBattleDuration = '30د';

  void _setRoomToolsVisible(bool value) {
    setState(() {
      _showRoomTools = value;
      if (value) {
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setEffectControlsVisible(bool value) {
    setState(() {
      _showEffectControls = value;
      if (!value) {
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setEffectSettingsPanelVisible(bool value) {
    setState(() {
      _showEffectSettingsPanel = value;
      if (value) {
        _showEffectControls = true;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setViewersPanelVisible(bool value) {
    setState(() {
      _showViewersPanel = value;
      if (value) {
        _showEffectSettingsPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setContributionPanelVisible(
    bool value, {
    bool returnToViewers = false,
  }) {
    setState(() {
      _showContributionPanel = value;
      _showViewersPanel = returnToViewers;
      if (value) {
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setPkPanelVisible(bool value) {
    setState(() {
      _showPkPanel = value;
      if (value) {
        _showEffectControls = true;
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkLiveSettingsPanel = false;
      }
      if (!value) {
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setPkLiveSettingsPanelVisible(bool value) {
    setState(() {
      _showPkLiveSettingsPanel = value;
      if (value) {
        _showEffectControls = true;
        _showPkPanel = false;
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/live150_background.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          if (_showEffectControls)
            Positioned.fill(
              child: Image.asset(
                'assets/images/live152_effect_overlay.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final topPadding = constraints.maxHeight >= 760 ? 50.0 : 24.0;
                  final videoHeight = math.min(
                    math.min(width * 0.89, constraints.maxHeight * 0.4),
                    333.0,
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(10, topPadding, 10, 12),
                    child: Column(
                      children: [
                        _LiveRoomHeader(
                          onClose: () => Navigator.of(context).pop(),
                          isCompact:
                              _showRoomTools ||
                              _showEffectControls ||
                              _showEffectSettingsPanel,
                        ),
                        const SizedBox(height: 14),
                        if (_showEffectControls)
                          SizedBox(
                            key: const ValueKey('live-room-effects-mode'),
                            height: videoHeight,
                          )
                        else
                          _LiveRoomVideoStage(height: videoHeight),
                        const SizedBox(height: 18),
                        Expanded(
                          child: _LiveRoomChatPanel(
                            comments: LiveRoomScreen._comments,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_showEffectControls)
                          _LiveRoomEffectsToolbar(
                            onGiftTap: () {},
                            onSettingsTap: () =>
                                _setEffectSettingsPanelVisible(true),
                            onPkTap: () => _setPkPanelVisible(true),
                            onNotificationTap: () {},
                            onGridTap: () {},
                            onPeopleTap: () => _setViewersPanelVisible(true),
                            onMessageTap: () {},
                          )
                        else
                          _LiveRoomComposer(
                            onGiftTap: () {},
                            onPeopleTap: () => _setViewersPanelVisible(true),
                            onChatTap: () {},
                            onRoomToolsTap: () => _setRoomToolsVisible(true),
                          ),
                        const SizedBox(height: 10),
                        Container(
                          width: 141,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_showRoomTools) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _setRoomToolsVisible(false),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                  child: Container(color: const Color(0x33424242)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _LiveRoomToolsSheet(
                onDismiss: () => _setRoomToolsVisible(false),
              ),
            ),
          ],
          if (_showEffectSettingsPanel) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setEffectSettingsPanelVisible(false),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _LiveRoomEffectSettingsPanel(
                onDismiss: () => _setEffectSettingsPanelVisible(false),
              ),
            ),
          ],
          if (_showViewersPanel) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setViewersPanelVisible(false),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                  child: Container(color: const Color(0x33424242)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _LiveRoomViewersPanel(
                onDismiss: () => _setViewersPanelVisible(false),
                onTopSupportersTap: () =>
                    _setContributionPanelVisible(true, returnToViewers: false),
              ),
            ),
          ],
          if (_showContributionPanel) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _setContributionPanelVisible(false, returnToViewers: true),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                  child: Container(color: const Color(0x33424242)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _LiveRoomContributionPanel(
                onDismiss: () =>
                    _setContributionPanelVisible(false, returnToViewers: true),
              ),
            ),
          ],
          if (_showPkPanel) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setPkPanelVisible(false),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                  child: Container(color: const Color(0x33424242)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _LiveRoomPkPanel(
                onDismiss: () => _setPkPanelVisible(false),
                onStartMatchingTap: () => _setPkLiveSettingsPanelVisible(true),
                onChallengeFriendsTap: () {},
              ),
            ),
          ],
          if (_showPkLiveSettingsPanel) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setPkLiveSettingsPanelVisible(false),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                  child: Container(color: const Color(0x33424242)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _LiveRoomPkLiveSettingsPanel(
                onDismiss: () => _setPkLiveSettingsPanelVisible(false),
                talkPermission: _pkTalkPermission,
                onTalkPermissionChanged: (value) {
                  setState(() => _pkTalkPermission = value);
                },
                partyInvitePermission: _pkPartyInvitePermission,
                onPartyInvitePermissionChanged: (value) {
                  setState(() => _pkPartyInvitePermission = value);
                },
                voiceRoomInvitePermission: _pkVoiceRoomInvitePermission,
                onVoiceRoomInvitePermissionChanged: (value) {
                  setState(() => _pkVoiceRoomInvitePermission = value);
                },
                chatPermission: _pkChatPermission,
                onChatPermissionChanged: (value) {
                  setState(() => _pkChatPermission = value);
                },
                battleDuration: _pkBattleDuration,
                onBattleDurationChanged: (value) {
                  setState(() => _pkBattleDuration = value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveRoomHeader extends StatelessWidget {
  const _LiveRoomHeader({required this.onClose, this.isCompact = false});

  final VoidCallback onClose;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          key: const ValueKey('live-room-close'),
          onTap: onClose,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: LiveRoomScreen._primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/live150_power.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _LiveRoomCounterChip(
          icon: Icons.people_alt_rounded,
          value: '393',
        ),
        const SizedBox(width: 8),
        const _LiveRoomCounterChip(
          assetIcon: 'assets/images/live150_coin.png',
          value: '214',
        ),
        const Spacer(),
        _LiveRoomHostBadge(isCompact: isCompact),
      ],
    );
  }
}

class _LiveRoomCounterChip extends StatelessWidget {
  const _LiveRoomCounterChip({required this.value, this.icon, this.assetIcon});

  final String value;
  final IconData? icon;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x5C285F98),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          if (assetIcon != null)
            Image.asset(assetIcon!, width: 10, height: 10)
          else
            Icon(icon, color: Colors.white, size: 10),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomHostBadge extends StatelessWidget {
  const _LiveRoomHostBadge({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isCompact ? 40.0 : 54.0;
    final avatarIconSize = isCompact ? 22.0 : 28.0;
    final badgeSize = isCompact ? 14.0 : 19.0;
    final badgeFontSize = isCompact ? 9.0 : 11.0;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'مداهم 777',
              key: ValueKey('live-room-title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'ID:1512345412',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB0D7F5), Color(0xFF285F98)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: avatarIconSize,
              ),
            ),
            Positioned(
              right: -1,
              top: -3,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: const BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+',
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
      ],
    );
  }
}

class _LiveRoomVideoStage extends StatelessWidget {
  const _LiveRoomVideoStage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: const [
                  _LiveRoomVideoPane(
                    imageAsset: 'assets/images/live150_video_left.png',
                    barColor: LiveRoomScreen._primaryBlue,
                    alignment: Alignment.topLeft,
                  ),
                  SizedBox(width: 2),
                  _LiveRoomVideoPane(
                    imageAsset: 'assets/images/live150_video_right.png',
                    barColor: LiveRoomScreen._accentRed,
                    alignment: Alignment.topRight,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 66,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0x9E000000),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      color: Colors.white,
                      size: 6,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '11:50',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 10,
            bottom: 10,
            child: _LiveRoomStageRating(color: LiveRoomScreen._primaryBlue),
          ),
          const Positioned(
            right: 10,
            bottom: 10,
            child: _LiveRoomStageRating(color: LiveRoomScreen._accentRed),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomVideoPane extends StatelessWidget {
  const _LiveRoomVideoPane({
    required this.imageAsset,
    required this.barColor,
    required this.alignment,
  });

  final String imageAsset;
  final Color barColor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 15,
              color: barColor,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Align(
                alignment: alignment,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person, color: Colors.white, size: 9),
                    SizedBox(width: 2),
                    Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomStageRating extends StatelessWidget {
  const _LiveRoomStageRating({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.only(left: index == 2 ? 0 : 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Icon(Icons.star_rounded, color: Colors.white, size: 10),
        ),
      ),
    );
  }
}

class _LiveRoomChatPanel extends StatelessWidget {
  const _LiveRoomChatPanel({required this.comments});

  final List<_LiveRoomComment> comments;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('live-room-screen'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: LiveRoomScreen._overlay,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'نصائح ادمنية: سوف يقوم بالتفتيش ادمن ب 24 ساعة , سيتم حظر\nحساب نشر المعلومات المنتهكة للقوانين واللوائح والملومات\nالمبتذلة والعنيفة وغيرها من المعلومات السيئة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: comments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                return _LiveRoomCommentRow(comment: comments[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomCommentRow extends StatelessWidget {
  const _LiveRoomCommentRow({required this.comment});

  final _LiveRoomComment comment;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/live150_comment_avatar.png',
              width: 20,
              height: 20,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  comment.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.message,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomComposer extends StatelessWidget {
  const _LiveRoomComposer({
    required this.onChatTap,
    required this.onGiftTap,
    required this.onRoomToolsTap,
    required this.onPeopleTap,
  });

  final VoidCallback onChatTap;
  final VoidCallback onGiftTap;
  final VoidCallback onRoomToolsTap;
  final VoidCallback onPeopleTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LiveRoomActionButton(
          icon: Icons.mail_rounded,
          semanticsLabel: 'live-room-chat-action',
          onTap: onChatTap,
        ),
        const SizedBox(width: 5),
        _LiveRoomGiftActionButton(onTap: onGiftTap),
        const SizedBox(width: 5),
        _LiveRoomActionButton(
          icon: Icons.grid_view_rounded,
          semanticsLabel: 'live-room-tools-action',
          onTap: onRoomToolsTap,
        ),
        const SizedBox(width: 5),
        _LiveRoomActionButton(
          icon: Icons.people_alt_rounded,
          semanticsLabel: 'live-room-people-action',
          onTap: onPeopleTap,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: LiveRoomScreen._overlay,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'محمد كيف حالك طمني عليك ؟',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/live150_send.png',
                  width: 21,
                  height: 21,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveRoomActionButton extends StatelessWidget {
  const _LiveRoomActionButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: LiveRoomScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }
}

class _LiveRoomGiftActionButton extends StatelessWidget {
  const _LiveRoomGiftActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'live-room-gift-action',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: LiveRoomScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/images/live150_gift.png',
              width: 17,
              height: 17,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveRoomToolsSheet extends StatelessWidget {
  const _LiveRoomToolsSheet({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-tools-sheet'),
        height: 118,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اداة الغرفة',
                  style: TextStyle(
                    color: LiveRoomScreen._primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LiveRoomToolAction(
                    icon: Icons.volume_up_rounded,
                    label: 'كتم الصوت',
                    semanticsLabel: 'live-room-tool-mute',
                    onTap: onDismiss,
                  ),
                  _LiveRoomToolAction(
                    icon: Icons.shield_outlined,
                    label: 'ابلاغ',
                    semanticsLabel: 'live-room-tool-report',
                    onTap: onDismiss,
                  ),
                  _LiveRoomToolAction(
                    icon: Icons.share_outlined,
                    label: 'شارك',
                    semanticsLabel: 'live-room-tool-share',
                    onTap: onDismiss,
                  ),
                  _LiveRoomToolAction(
                    icon: Icons.auto_awesome_outlined,
                    label: 'اعدادات التاثير',
                    semanticsLabel: 'live-room-tool-effects',
                    onTap: () {
                      onDismiss();
                      final state = context
                          .findAncestorStateOfType<_LiveRoomScreenState>();
                      state?._setEffectControlsVisible(true);
                    },
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

class _LiveRoomToolAction extends StatelessWidget {
  const _LiveRoomToolAction({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEDFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: LiveRoomScreen._primaryBlue, size: 24),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LiveRoomScreen._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRoomComment {
  const _LiveRoomComment({required this.name, required this.message});

  final String name;
  final String message;
}

class _LiveRoomEffectsToolbar extends StatelessWidget {
  const _LiveRoomEffectsToolbar({
    required this.onGiftTap,
    required this.onSettingsTap,
    required this.onPkTap,
    required this.onNotificationTap,
    required this.onGridTap,
    required this.onPeopleTap,
    required this.onMessageTap,
  });

  final VoidCallback onGiftTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onPkTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onGridTap;
  final VoidCallback onPeopleTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-gift'),
            semanticsLabel: 'live-room-effects-gift',
            onTap: onGiftTap,
            child: Image.asset(
              'assets/images/live150_gift.png',
              width: 17,
              height: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-settings'),
            semanticsLabel: 'live-room-effects-settings',
            onTap: onSettingsTap,
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-pk'),
            semanticsLabel: 'live-room-effects-pk',
            onTap: onPkTap,
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'P',
                    style: TextStyle(
                      color: Color(0xFFFF9000),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'K',
                    style: TextStyle(
                      color: Color(0xFF6D9BFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-notification'),
            semanticsLabel: 'live-room-effects-notification',
            onTap: onNotificationTap,
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-grid'),
            semanticsLabel: 'live-room-effects-grid',
            onTap: onGridTap,
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-people'),
            semanticsLabel: 'live-room-effects-people',
            onTap: onPeopleTap,
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-message'),
            semanticsLabel: 'live-room-effects-message',
            onTap: onMessageTap,
            child: const Icon(
              Icons.message_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomEffectSettingsPanel extends StatelessWidget {
  const _LiveRoomEffectSettingsPanel({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-effect-settings-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: const [
                    _LiveRoomManagementSection(
                      title: 'ادارة البث',
                      items: [
                        _LiveRoomManagementItemData(
                          label: 'جمال',
                          assetIcon: 'assets/images/live153_beauty.png',
                        ),
                        _LiveRoomManagementItemData(
                          label: 'ملصق',
                          assetIcon: 'assets/images/live153_sticker.png',
                        ),
                        _LiveRoomManagementItemData(
                          label: 'واجهة',
                          icon: Icons.photo_camera_outlined,
                        ),
                        _LiveRoomManagementItemData(
                          label: 'كتم الصوت',
                          icon: Icons.mic_off_outlined,
                        ),
                        _LiveRoomManagementItemData(
                          label: 'مراقب سماعة\nالاذن',
                          icon: Icons.headset_rounded,
                          multiline: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _LiveRoomManagementSection(
                      title: 'ادارة الغرفة',
                      items: [
                        _LiveRoomManagementItemData(
                          label: 'نشرة الغرفة',
                          icon: Icons.campaign_outlined,
                        ),
                        _LiveRoomManagementItemData(
                          label: 'اعدادات رسالة\nالترحيب',
                          icon: Icons.mark_chat_read_outlined,
                          multiline: true,
                        ),
                        _LiveRoomManagementItemData(
                          label: 'مستخدم جديد',
                          icon: Icons.person_add_alt_1_rounded,
                        ),
                        _LiveRoomManagementItemData(
                          label: 'مسؤول الغرفة',
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                        _LiveRoomManagementItemData(
                          label: 'القيمة في ترتيب\nالدخولية',
                          icon: Icons.leaderboard_outlined,
                          multiline: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _LiveRoomManagementSection(
                      title: 'مركز الالعاب',
                      items: [
                        _LiveRoomManagementItemData(
                          label: 'Valorant',
                          assetIcon: 'assets/images/live153_game.png',
                        ),
                        _LiveRoomManagementItemData(
                          label: 'Valorant',
                          assetIcon: 'assets/images/live153_game.png',
                        ),
                        _LiveRoomManagementItemData(
                          label: 'Valorant',
                          assetIcon: 'assets/images/live153_game.png',
                        ),
                        _LiveRoomManagementItemData(
                          label: 'Valorant',
                          assetIcon: 'assets/images/live153_game.png',
                        ),
                        _LiveRoomManagementItemData(
                          label: 'Valorant',
                          assetIcon: 'assets/images/live153_game.png',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomManagementSection extends StatelessWidget {
  const _LiveRoomManagementSection({required this.title, required this.items});

  final String title;
  final List<_LiveRoomManagementItemData> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 10,
            children: items
                .map((item) => _LiveRoomManagementItem(data: item))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomManagementItemData {
  const _LiveRoomManagementItemData({
    required this.label,
    this.icon,
    this.assetIcon,
    this.multiline = false,
  });

  final String label;
  final IconData? icon;
  final String? assetIcon;
  final bool multiline;
}

class _LiveRoomManagementItem extends StatelessWidget {
  const _LiveRoomManagementItem({required this.data});

  final _LiveRoomManagementItemData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEDFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: data.assetIcon != null
                  ? Image.asset(
                      data.assetIcon!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      data.icon,
                      color: LiveRoomScreen._primaryBlue,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: data.multiline ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LiveRoomScreen._primaryBlue,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomViewersPanel extends StatelessWidget {
  const _LiveRoomViewersPanel({
    required this.onDismiss,
    required this.onTopSupportersTap,
  });

  final VoidCallback onDismiss;
  final VoidCallback onTopSupportersTap;

  static const List<String> _names = [
    'Mohammed Ahmed',
    'Mohammed Ahmed',
    'Mohammed Ahmed',
    'Mohammed Ahmed',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-viewers-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'المشاهدين',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _names.length,
                separatorBuilder: (_, _) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  return _LiveRoomViewerRow(
                    rank: index + 1,
                    name: _names[index],
                    isTopSupporter: index == 0,
                    onTopSupportersTap: onTopSupportersTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomViewerRow extends StatelessWidget {
  const _LiveRoomViewerRow({
    required this.rank,
    required this.name,
    required this.isTopSupporter,
    required this.onTopSupportersTap,
  });

  final int rank;
  final String name;
  final bool isTopSupporter;
  final VoidCallback onTopSupportersTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Text(
            '$rank',
            style: const TextStyle(
              color: LiveRoomScreen._primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          ClipOval(
            child: Image.asset(
              'assets/images/live150_comment_avatar.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isTopSupporter) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'live-room-top-supporters-entry',
                    button: true,
                    child: GestureDetector(
                      onTap: onTopSupportersTap,
                      child: Container(
                        width: 61,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFBEAC), Color(0xFFFFBF00)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'افضل الداعمين',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomContributionPanel extends StatelessWidget {
  const _LiveRoomContributionPanel({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-contribution-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'قائمة المساهمات لهذه الجولة',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 46),
            Image.asset(
              'assets/images/live155_empty_state.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 5),
            const Text(
              'لا يوجد الان بيانات',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(height: 1, color: const Color(0xFFD9D9D9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 10, 40, 9),
              child: Row(
                children: [
                  Expanded(
                    child: _LiveRoomContributionStat(
                      value: '100',
                      label: 'الهدية الاجمالية',
                      icon: Image.asset(
                        'assets/images/live155_diamond.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  const Expanded(
                    child: _LiveRoomContributionStat(
                      value: '100',
                      label: 'عدد المرسلين',
                      icon: Icon(
                        Icons.groups_2_outlined,
                        color: LiveRoomScreen._primaryBlue,
                        size: 24,
                      ),
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

class _LiveRoomContributionStat extends StatelessWidget {
  const _LiveRoomContributionStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            icon,
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFBEBEBE),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LiveRoomPkPanel extends StatelessWidget {
  const _LiveRoomPkPanel({
    required this.onDismiss,
    required this.onStartMatchingTap,
    required this.onChallengeFriendsTap,
  });

  final VoidCallback onDismiss;
  final VoidCallback onStartMatchingTap;
  final VoidCallback onChallengeFriendsTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-pk-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1v1 PK',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: _LiveRoomPkCard(
                backgroundColor: Color(0xFFF2496D),
                leftColor: Color(0xFF9345CF),
                title: 'نمط المطابقة',
                description:
                    'سيطابقك النظام مع خصوم ذوي قوة مماثلة\nولك.افز واحصل علي نقاط المعركة',
                buttonText: 'بدء المطابقة',
                showPkMark: true,
                onButtonTap: onStartMatchingTap,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: _LiveRoomPkCard(
                backgroundColor: Color(0xFF3E18C5),
                leftColor: Color(0xFF3E18C5),
                title: 'وضع الدعوة',
                description: 'دعوة اصدقائك لا يجلب نقاط المعركة',
                buttonText: 'تحدي الاصدقاء',
                showPkMark: false,
                onButtonTap: onChallengeFriendsTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomPkCard extends StatelessWidget {
  const _LiveRoomPkCard({
    required this.backgroundColor,
    required this.leftColor,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.showPkMark,
    required this.onButtonTap,
  });

  final Color backgroundColor;
  final Color leftColor;
  final String title;
  final String description;
  final String buttonText;
  final bool showPkMark;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 97,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: leftColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (showPkMark)
            const Positioned(
              left: 12,
              top: 16,
              child: Text(
                'PK',
                style: TextStyle(
                  color: Color(0xFFFFA700),
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onButtonTap,
                        child: Container(
                          width: 87,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
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
      ),
    );
  }
}

class _LiveRoomPkLiveSettingsPanel extends StatelessWidget {
  const _LiveRoomPkLiveSettingsPanel({
    required this.onDismiss,
    required this.talkPermission,
    required this.onTalkPermissionChanged,
    required this.partyInvitePermission,
    required this.onPartyInvitePermissionChanged,
    required this.voiceRoomInvitePermission,
    required this.onVoiceRoomInvitePermissionChanged,
    required this.chatPermission,
    required this.onChatPermissionChanged,
    required this.battleDuration,
    required this.onBattleDurationChanged,
  });

  final VoidCallback onDismiss;
  final String talkPermission;
  final ValueChanged<String> onTalkPermissionChanged;
  final String partyInvitePermission;
  final ValueChanged<String> onPartyInvitePermissionChanged;
  final String voiceRoomInvitePermission;
  final ValueChanged<String> onVoiceRoomInvitePermissionChanged;
  final String chatPermission;
  final ValueChanged<String> onChatPermissionChanged;
  final String battleDuration;
  final ValueChanged<String> onBattleDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-pk-settings-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 141,
                  height: 8,
                  decoration: BoxDecoration(
                    color: LiveRoomScreen._primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(19, 15, 19, 0),
              child: Text(
                'اعدادات الايف',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LiveRoomPermissionRow(
              title: 'من يستطيع التحدث في حياتي',
              selectedValue: talkPermission,
              onChanged: onTalkPermissionChanged,
            ),
            _LiveRoomPermissionRow(
              title: 'من يمكنه دعوتي الي Party',
              selectedValue: partyInvitePermission,
              onChanged: onPartyInvitePermissionChanged,
            ),
            _LiveRoomPermissionRow(
              title: 'من يستطيع دعوتي الي غرفة صوتيه',
              selectedValue: voiceRoomInvitePermission,
              onChanged: onVoiceRoomInvitePermissionChanged,
            ),
            _LiveRoomPermissionRow(
              title: 'من يمكنه الدردشة',
              selectedValue: chatPermission,
              onChanged: onChatPermissionChanged,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(19, 10, 19, 0),
              child: Text(
                'مدة المعركة',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 6, 19, 0),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LiveRoomDurationOption(
                      label: '3د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '5د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '15د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '30د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '60د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(height: 2, color: const Color(0xFFE8E8E8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 18, 47, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _LiveRoomFooterAction(
                    icon: Icons.mic_rounded,
                    semanticsLabel: 'live-room-pk-settings-mic',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.music_note_rounded,
                    semanticsLabel: 'live-room-pk-settings-music',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.camera_alt_rounded,
                    semanticsLabel: 'live-room-pk-settings-camera',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.grid_view_rounded,
                    semanticsLabel: 'live-room-pk-settings-grid',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.videocam_off_rounded,
                    semanticsLabel: 'live-room-pk-settings-camera-off',
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

class _LiveRoomPermissionRow extends StatelessWidget {
  const _LiveRoomPermissionRow({
    required this.title,
    required this.selectedValue,
    required this.onChanged,
  });

  final String title;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LiveRoomRadioOption(
                  label: 'شبكتي',
                  selected: selectedValue == 'شبكتي',
                  onTap: () => onChanged('شبكتي'),
                ),
                const SizedBox(width: 26),
                _LiveRoomRadioOption(
                  label: 'عند الطلب',
                  selected: selectedValue == 'عند الطلب',
                  onTap: () => onChanged('عند الطلب'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomRadioOption extends StatelessWidget {
  const _LiveRoomRadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? LiveRoomScreen._primaryBlue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: LiveRoomScreen._primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomDurationOption extends StatelessWidget {
  const _LiveRoomDurationOption({
    required this.label,
    required this.selectedValue,
    required this.onChanged,
  });

  final String label;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = label == selectedValue;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? LiveRoomScreen._primaryBlue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: LiveRoomScreen._primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomFooterAction extends StatelessWidget {
  const _LiveRoomFooterAction({
    required this.icon,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFDCEDFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: LiveRoomScreen._primaryBlue, size: 24),
      ),
    );
  }
}

class _LiveRoomEffectCircle extends StatelessWidget {
  const _LiveRoomEffectCircle({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: LiveRoomScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
