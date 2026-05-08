import 'package:flutter/material.dart';

import '../../../../core/widgets/resolved_image.dart';
import '../../data/profile_account_repository.dart';

class ProfileDecoratedAvatar extends StatelessWidget {
  const ProfileDecoratedAvatar({
    super.key,
    required this.avatarAsset,
    this.appearance = const ProfileAppearanceData(),
    this.size = 80,
    this.showOnlineBadge = false,
    this.onlineBadgeBorderColor = Colors.white,
  });

  final String avatarAsset;
  final ProfileAppearanceData appearance;
  final double size;
  final bool showOnlineBadge;
  final Color onlineBadgeBorderColor;

  @override
  Widget build(BuildContext context) {
    final frameAsset = appearance.avatarFrameAssetPath;
    final badgeAsset = appearance.profileBadgeAssetPath;
    final framePadding = size * 0.14;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
            ),
            clipBehavior: Clip.antiAlias,
            child: ResolvedImage(path: avatarAsset, fit: BoxFit.cover),
          ),
          if (frameAsset != null && frameAsset.trim().isNotEmpty)
            Positioned(
              key: const ValueKey('profile-avatar-frame'),
              left: -framePadding,
              top: -framePadding,
              right: -framePadding,
              bottom: -framePadding,
              child: IgnorePointer(
                child: ResolvedImage(
                  path: frameAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          if (badgeAsset != null && badgeAsset.trim().isNotEmpty)
            PositionedDirectional(
              key: const ValueKey('profile-avatar-badge'),
              start: -2,
              bottom: -2,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                padding: EdgeInsets.all(size * 0.045),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD36A),
                    width: size * 0.025,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ResolvedImage(
                  path: badgeAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          if (showOnlineBadge)
            PositionedDirectional(
              end: 2,
              bottom: 2,
              child: Container(
                width: size * 0.19,
                height: size * 0.19,
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: onlineBadgeBorderColor,
                    width: size * 0.025,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
