import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../data/room_game_repository.dart';
import '../widgets/room_background_view.dart';

class RoomGameLobbyScreenArgs {
  const RoomGameLobbyScreenArgs({
    required this.roomId,
    required this.gameId,
  });

  final int roomId;
  final int gameId;
}

class RoomGameLobbyScreen extends StatefulWidget {
  const RoomGameLobbyScreen({super.key, required this.args});

  final RoomGameLobbyScreenArgs args;

  @override
  State<RoomGameLobbyScreen> createState() => _RoomGameLobbyScreenState();
}

class _RoomGameLobbyScreenState extends State<RoomGameLobbyScreen> {
  late Future<RoomGameLobbyData> _lobbyFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _lobbyFuture = _loadLobby();
  }

  Future<RoomGameLobbyData> _loadLobby() {
    return RoomGameRepository.instance.loadLobby(
      roomId: widget.args.roomId,
      gameId: widget.args.gameId,
    );
  }

  Future<void> _refresh() async {
    final future = _loadLobby();
    setState(() {
      _lobbyFuture = future;
    });
    await future;
  }

  Future<void> _joinGame() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final data = await RoomGameRepository.instance.joinGame(
        roomId: widget.args.roomId,
        gameId: widget.args.gameId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lobbyFuture = Future<RoomGameLobbyData>.value(data);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الانضمام إلى اللعبة')),
      );
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
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _leaveSession(int sessionId) async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final data = await RoomGameRepository.instance.leaveSession(
        roomId: widget.args.roomId,
        sessionId: sessionId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lobbyFuture = Future<RoomGameLobbyData>.value(data);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت مغادرة الجلسة')),
      );
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoomBackgroundView(),
          SafeArea(
            child: ResponsiveContent(
              padding: EdgeInsets.fromLTRB(
                metrics.pageHorizontalPadding(),
                metrics.spacing(16),
                metrics.pageHorizontalPadding(),
                metrics.spacing(20),
              ),
              child: FutureBuilder<RoomGameLobbyData>(
                future: _lobbyFuture,
                builder: (context, snapshot) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height -
                              metrics.spacing(120),
                        ),
                        child: _buildBody(context, snapshot, metrics),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<RoomGameLobbyData> snapshot,
    ResponsiveMetrics metrics,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 120),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LobbyHeader(onBackTap: () => Navigator.of(context).pop()),
          SizedBox(height: metrics.spacing(36)),
          _LobbyMessageCard(
            title: 'تعذر تحميل بيانات اللعبة',
            subtitle: 'أعد السحب لأسفل أو استخدم زر التحديث للمحاولة مرة أخرى.',
            actionLabel: 'تحديث',
            onActionTap: _refresh,
          ),
        ],
      );
    }

    final lobby = snapshot.data!;
    final session = lobby.activeSession;
    final joined = session?.isJoined == true;
    final playerCount = session?.playerCount ?? 0;
    final capacityText = '$playerCount/${lobby.game.maxPlayers}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LobbyHeader(onBackTap: () => Navigator.of(context).pop()),
        SizedBox(height: metrics.spacing(18)),
        _LobbyGameCard(lobby: lobby),
        SizedBox(height: metrics.spacing(16)),
        _LobbyInfoRow(
          title: 'سعة الجلسة',
          value: capacityText,
          icon: Icons.groups_rounded,
        ),
        SizedBox(height: metrics.spacing(10)),
        _LobbyInfoRow(
          title: 'الحالة الحالية',
          value: session?.statusLabel ?? 'لا توجد جلسة نشطة',
          icon: Icons.videogame_asset_rounded,
        ),
        SizedBox(height: metrics.spacing(10)),
        _LobbyInfoRow(
          title: 'الحد الأدنى للبدء',
          value: '${lobby.game.minPlayers} لاعبين',
          icon: Icons.flag_circle_rounded,
        ),
        SizedBox(height: metrics.spacing(18)),
        Text(
          session == null ? 'لاعبو الجلسة' : 'المنضمون حاليًا',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: metrics.font(15, min: 14, max: 17),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: metrics.spacing(12)),
        if (session == null || session.players.isEmpty)
          _LobbyEmptyPlayersCard(gameName: lobby.game.name)
        else
          ...session.players.map(
            (player) => Padding(
              padding: EdgeInsets.only(bottom: metrics.spacing(10)),
              child: _LobbyPlayerCard(player: player),
            ),
          ),
        SizedBox(height: metrics.spacing(20)),
        Semantics(
          label: joined ? 'room-game-leave' : 'room-game-join',
          button: true,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : joined
                ? () => _leaveSession(session!.id)
                : _joinGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF285F98),
              disabledBackgroundColor: const Color(0xFF7E9FC0),
              padding: EdgeInsets.symmetric(vertical: metrics.spacing(16)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: metrics.spacing(18),
                    height: metrics.spacing(18),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    joined ? 'مغادرة الجلسة' : 'الانضمام إلى اللعبة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.font(15, min: 14, max: 17),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        SizedBox(height: metrics.spacing(10)),
        OutlinedButton(
          onPressed: _refresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
            padding: EdgeInsets.symmetric(vertical: metrics.spacing(14)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'تحديث الحالة',
            style: TextStyle(
              fontSize: metrics.font(13, min: 12, max: 15),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Row(
      children: [
        InkWell(
          onTap: onBackTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: metrics.spacing(42),
            height: metrics.spacing(42),
            decoration: BoxDecoration(
              color: const Color(0xFF285F98),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Semantics(
          container: true,
          label: 'room-game-lobby-screen',
          child: ExcludeSemantics(
            child: Text(
              'جلسة اللعبة',
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.font(18, min: 17, max: 20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LobbyGameCard extends StatelessWidget {
  const _LobbyGameCard({required this.lobby});

  final RoomGameLobbyData lobby;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.all(metrics.spacing(18)),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lobby.game.name,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: metrics.font(18, min: 17, max: 20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: metrics.spacing(6)),
                    Text(
                      lobby.game.categoryLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: const Color(0xFF285F98),
                        fontSize: metrics.font(12, min: 11, max: 13),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: metrics.spacing(14)),
              Image.asset(
                lobby.game.iconAsset,
                width: metrics.spacing(58, min: 52, max: 62),
                height: metrics.spacing(58, min: 52, max: 62),
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
          SizedBox(height: metrics.spacing(16)),
          Text(
            lobby.game.descriptionText,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF434A54),
              fontSize: metrics.font(12, min: 11, max: 13),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyInfoRow extends StatelessWidget {
  const _LobbyInfoRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(16),
        vertical: metrics.spacing(12),
      ),
      decoration: BoxDecoration(
        color: const Color(0x9923262A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: metrics.spacing(18)),
          const Spacer(),
          Flexible(
            child: Text(
              '$value : $title',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.font(12, min: 11, max: 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyPlayerCard extends StatelessWidget {
  const _LobbyPlayerCard({required this.player});

  final RoomGamePlayerData player;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(16),
        vertical: metrics.spacing(12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: metrics.spacing(34),
            height: metrics.spacing(34),
            decoration: BoxDecoration(
              color: const Color(0xFF285F98),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                '${player.seatNumber}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: metrics.font(13, min: 12, max: 14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: metrics.spacing(12)),
          Expanded(
            child: Text(
              player.playerName,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black,
                fontSize: metrics.font(14, min: 13, max: 15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyEmptyPlayersCard extends StatelessWidget {
  const _LobbyEmptyPlayersCard({required this.gameName});

  final String gameName;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(18),
        vertical: metrics.spacing(20),
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'لا توجد جلسة نشطة حاليًا',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black,
              fontSize: metrics.font(14, min: 13, max: 16),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: metrics.spacing(6)),
          Text(
            'اضغط على زر الانضمام لبدء أول جلسة في $gameName داخل الغرفة.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF5B6470),
              fontSize: metrics.font(12, min: 11, max: 13),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyMessageCard extends StatelessWidget {
  const _LobbyMessageCard({
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
    return Container(
      padding: EdgeInsets.all(metrics.spacing(20)),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: metrics.font(16, min: 15, max: 18),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: metrics.spacing(10)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5B6470),
              fontSize: metrics.font(12, min: 11, max: 13),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: metrics.spacing(18)),
          ElevatedButton(
            onPressed: onActionTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF285F98),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: metrics.spacing(22),
                vertical: metrics.spacing(12),
              ),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.font(12, min: 11, max: 13),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
