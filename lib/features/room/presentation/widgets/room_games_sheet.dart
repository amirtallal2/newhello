import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/room_game_repository.dart';
import '../screens/room_game_lobby_screen.dart';

Future<void> showRoomGamesSheet(BuildContext context, {required int roomId}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-games-dialog',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _RoomGamesDialog(rootContext: context, roomId: roomId);
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

class _RoomGamesDialog extends StatefulWidget {
  const _RoomGamesDialog({required this.rootContext, required this.roomId});

  final BuildContext rootContext;
  final int roomId;

  @override
  State<_RoomGamesDialog> createState() => _RoomGamesDialogState();
}

class _RoomGamesDialogState extends State<_RoomGamesDialog> {
  late Future<RoomGameCatalogData> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = RoomGameRepository.instance.loadCatalog(roomId: widget.roomId);
  }

  void _reload() {
    setState(() {
      _catalogFuture = RoomGameRepository.instance.loadCatalog(roomId: widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: metrics.spacing(250, min: 250),
                  maxHeight: metrics.sheetMaxHeight(0.56, minHeight: 300),
                ),
                child: Column(
                  children: [
                    SizedBox(height: metrics.spacing(15)),
                    Container(
                      width: metrics.spacing(141),
                      height: metrics.spacing(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF285F98),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                    ),
                    SizedBox(height: metrics.spacing(22)),
                    Expanded(
                      child: FutureBuilder<RoomGameCatalogData>(
                        future: _catalogFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return _RoomGamesFeedback(
                              title: 'تعذر تحميل الألعاب',
                              subtitle: 'تأكد من اتصال التطبيق بالباك اند ثم أعد المحاولة.',
                              actionLabel: 'إعادة المحاولة',
                              onActionTap: _reload,
                            );
                          }

                          final catalog = snapshot.data;
                          final games = catalog?.games ?? const <RoomGameItemData>[];
                          if (games.isEmpty) {
                            return _RoomGamesFeedback(
                              title: 'لا توجد ألعاب متاحة',
                              subtitle: 'أضف الألعاب من لوحة التحكم أو فعّل العناصر المخفية.',
                              actionLabel: 'تحديث',
                              onActionTap: _reload,
                            );
                          }

                          final sections = <String, List<RoomGameItemData>>{};
                          for (final game in games) {
                            sections.putIfAbsent(game.categoryLabel, () => <RoomGameItemData>[]).add(game);
                          }

                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              metrics.pageHorizontalPadding(regular: 20, compact: 16),
                              0,
                              metrics.pageHorizontalPadding(regular: 20, compact: 16),
                              metrics.spacing(24),
                            ),
                            child: Column(
                              children: sections.entries.map((entry) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: metrics.spacing(22)),
                                  child: _RoomGameSection(
                                    title: entry.key,
                                    games: entry.value,
                                    onGameTap: (game) => _openGameLobby(
                                      dialogContext: context,
                                      gameId: game.id,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
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

  void _openGameLobby({
    required BuildContext dialogContext,
    required int gameId,
  }) {
    Navigator.of(dialogContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.rootContext.mounted) {
        return;
      }

      Navigator.of(widget.rootContext).pushNamed(
        AppRoutes.roomGameLobby,
        arguments: RoomGameLobbyScreenArgs(roomId: widget.roomId, gameId: gameId),
      );
    });
  }
}

class _RoomGameSection extends StatelessWidget {
  const _RoomGameSection({
    required this.title,
    required this.games,
    required this.onGameTap,
  });

  final String title;
  final List<RoomGameItemData> games;
  final ValueChanged<RoomGameItemData> onGameTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Column(
      children: [
        _RoomGamesSectionTitle(title: title),
        SizedBox(height: metrics.spacing(18)),
        Wrap(
          alignment: WrapAlignment.end,
          runAlignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: metrics.spacing(34, min: 24, max: 44),
          runSpacing: metrics.spacing(18, min: 14),
          children: games.map((game) {
            return _RoomGameItem(
              semanticLabel: 'room-game-${game.gameKey}',
              title: game.name,
              assetPath: game.iconAsset,
              badgeText: game.activeSession == null
                  ? null
                  : '${game.activeSession!.playerCount}/${game.activeSession!.maxPlayers}',
              onTap: () => onGameTap(game),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoomGamesSectionTitle extends StatelessWidget {
  const _RoomGamesSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.spacing(4)),
      child: Row(
        children: [
          Container(
            width: metrics.spacing(7),
            height: metrics.spacing(36),
            decoration: BoxDecoration(
              color: const Color(0xFF285F98),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black,
              fontSize: metrics.font(12, min: 11, max: 14),
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
    this.badgeText,
  });

  final String semanticLabel;
  final String title;
  final String assetPath;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: metrics.spacing(64, min: 56, max: 70),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      assetPath,
                      width: metrics.spacing(40, min: 36, max: 44),
                      height: metrics.spacing(40, min: 36, max: 44),
                      filterQuality: FilterQuality.high,
                    ),
                    if (badgeText != null)
                      Positioned(
                        left: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF285F98),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: metrics.font(8, min: 7, max: 9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: metrics.spacing(10)),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: metrics.font(8, min: 8, max: 10),
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

class _RoomGamesFeedback extends StatelessWidget {
  const _RoomGamesFeedback({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.spacing(26)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: metrics.font(16, min: 15, max: 18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: metrics.spacing(10)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF5B6470),
                fontSize: metrics.font(12, min: 11, max: 13),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: metrics.spacing(18)),
            ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF285F98),
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.spacing(22),
                  vertical: metrics.spacing(10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: metrics.font(12, min: 11, max: 13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
