import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/room_repository.dart';
import '../controllers/room_session_controller.dart';

Future<void> showRoomSeatJoinRequestsSheet(
  BuildContext context, {
  required int seatNumber,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-seat-join-requests-dialog',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _RoomSeatJoinRequestsDialog(seatNumber: seatNumber);
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

class _RoomSeatJoinRequestsDialog extends StatelessWidget {
  const _RoomSeatJoinRequestsDialog({required this.seatNumber});

  final int seatNumber;

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
            label: 'room-seat-join-requests-sheet',
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
                      'طلب الانضمام الي المقعد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: FutureBuilder<List<RoomSeatRequestData>>(
                        future: RoomSessionController.instance.loadSeatRequests(
                          seatNumber,
                        ),
                        builder: (context, snapshot) {
                          final requests = snapshot.data;
                          final displayRequests =
                              requests != null && requests.isNotEmpty
                              ? requests
                              : List<RoomSeatRequestData>.generate(
                                  4,
                                  (index) => RoomSeatRequestData(
                                    id: index + 1,
                                    roomId:
                                        RoomSessionController
                                            .instance
                                            .activeRoomId,
                                    seatNumber: seatNumber,
                                    requesterName: 'Mohammed Ahmed',
                                    requesterAvatarAsset:
                                        'assets/images/profile_avatar.png',
                                    status: 'pending',
                                  ),
                                );

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: displayRequests.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final request = displayRequests[index];
                              return _JoinRequestRow(
                                rank: index + 1,
                                name: request.requesterName,
                                seatNumber: request.seatNumber,
                                avatarAsset: request.requesterAvatarAsset,
                              );
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
                      label: 'room-seat-join-requests-cancel',
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

class _JoinRequestRow extends StatelessWidget {
  const _JoinRequestRow({
    required this.rank,
    required this.name,
    required this.seatNumber,
    required this.avatarAsset,
  });

  final int rank;
  final String name;
  final int seatNumber;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x14285F98),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/room_small_mic_icon.png',
              width: 20,
              height: 20,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x14285F98),
            ),
            alignment: Alignment.center,
            child: Text(
              '$seatNumber',
              style: const TextStyle(
                color: Color(0xFF285F98),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(avatarAsset),
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
          const SizedBox(width: 14),
          SizedBox(
            width: 10,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF285F98),
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
