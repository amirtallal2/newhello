import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

Future<void> showRoomGamesSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-games-dialog',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _RoomGamesDialog(rootContext: context);
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

class _RoomGamesDialog extends StatelessWidget {
  const _RoomGamesDialog({required this.rootContext});

  final BuildContext rootContext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: const Color(0x05FFFFFF)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Semantics(
            container: true,
            label: 'room-games-sheet',
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 328,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Container(
                      width: 141,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF285F98),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _RoomGamesSectionTitle(title: 'العاب الحظ'),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RoomGameItem(
                            semanticLabel: 'room-game-wheel',
                            title: 'عجلة الحظ',
                            assetPath: 'assets/images/room_game_wheel_icon.png',
                            onTap: () => _openPlaceholder(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _RoomGamesSectionTitle(title: 'العاب اللوح'),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RoomGameItem(
                            semanticLabel: 'room-game-ludo',
                            title: 'لودو',
                            assetPath: 'assets/images/room_game_ludo_icon.png',
                            onTap: () => _openPlaceholder(context),
                          ),
                          const SizedBox(width: 80),
                          _RoomGameItem(
                            semanticLabel: 'room-game-domino',
                            title: 'دومينو',
                            assetPath:
                                'assets/images/room_game_domino_icon.png',
                            onTap: () => _openPlaceholder(context),
                          ),
                        ],
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
  }

  void _openPlaceholder(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!rootContext.mounted) {
        return;
      }

      Navigator.of(rootContext).pushNamed(AppRoutes.bootstrap);
    });
  }
}

class _RoomGamesSectionTitle extends StatelessWidget {
  const _RoomGamesSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF285F98),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomGameItem extends StatelessWidget {
  const _RoomGameItem({
    required this.semanticLabel,
    required this.title,
    required this.assetPath,
    required this.onTap,
  });

  final String semanticLabel;
  final String title;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  assetPath,
                  width: 40,
                  height: 40,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
