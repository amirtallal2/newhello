import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/room_gift_repository.dart';
import '../controllers/room_session_controller.dart';

Future<void> showRoomReceivedGiftsSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-received-gifts-dialog',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return const _RoomReceivedGiftsDialog();
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

class _RoomReceivedGiftsDialog extends StatelessWidget {
  const _RoomReceivedGiftsDialog();

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
            label: 'room-received-gifts-sheet',
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 416,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'الهدايا المستلمة من الروم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: FutureBuilder<List<RoomGiftSupporterData>>(
                        future: RoomGiftRepository.instance.loadRoomSupporters(
                          roomId: RoomSessionController.instance.activeRoomId,
                        ),
                        builder: (context, snapshot) {
                          final entries =
                              snapshot.data != null && snapshot.data!.isNotEmpty
                              ? snapshot.data!
                              : const <RoomGiftSupporterData>[
                                  RoomGiftSupporterData(
                                    rank: 1,
                                    name: 'Mohammed Ahmed',
                                    avatarAsset:
                                        'assets/images/profile_avatar.png',
                                    totalCoins: 200,
                                    coinsLabel: '200 Coin',
                                    isTopSupporter: true,
                                  ),
                                  RoomGiftSupporterData(
                                    rank: 2,
                                    name: 'Mohammed Ahmed',
                                    avatarAsset:
                                        'assets/images/profile_avatar.png',
                                    totalCoins: 200,
                                    coinsLabel: '200 Coin',
                                    isTopSupporter: false,
                                  ),
                                  RoomGiftSupporterData(
                                    rank: 3,
                                    name: 'Mohammed Ahmed',
                                    avatarAsset:
                                        'assets/images/profile_avatar.png',
                                    totalCoins: 200,
                                    coinsLabel: '200 Coin',
                                    isTopSupporter: false,
                                  ),
                                  RoomGiftSupporterData(
                                    rank: 4,
                                    name: 'Mohammed Ahmed',
                                    avatarAsset:
                                        'assets/images/profile_avatar.png',
                                    totalCoins: 21,
                                    coinsLabel: '21 Coin',
                                    isTopSupporter: false,
                                  ),
                                ];

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: entries.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              return _SupporterRow(entry: entries[index]);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE9E9E9),
                    ),
                    Semantics(
                      label: 'room-received-gifts-cancel',
                      button: true,
                      child: ExcludeSemantics(
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            height: 58,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                'الغاء',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
        ),
      ],
    );
  }
}

class _SupporterRow extends StatelessWidget {
  const _SupporterRow({required this.entry});

  final RoomGiftSupporterData entry;

  @override
  Widget build(BuildContext context) {
    final rankColor = entry.rank <= 3 ? const Color(0xFF285F98) : Colors.black;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Image.asset(
            'assets/images/room_coin_small_icon.png',
            width: 15,
            height: 15,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 4),
          Text(
            entry.coinsLabel,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (entry.isTopSupporter)
            Container(
              width: 61,
              height: 14,
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
                  fontSize: 6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(width: 61, height: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                entry.name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(entry.avatarAsset),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 10,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rankColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
