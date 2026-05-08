import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/resolved_image.dart';
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
            label: 'room-seat-join-requests-sheet',
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: metrics.sheetMaxHeight(0.70, minHeight: 320),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(height: metrics.spacing(20, min: 14, max: 20)),
                      Text(
                        'طلب الانضمام الي المقعد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: metrics.font(15, min: 13, max: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: metrics.spacing(22, min: 16, max: 22)),
                      Expanded(
                        child: FutureBuilder<List<RoomSeatRequestData>>(
                          future: RoomSessionController.instance
                              .loadSeatRequests(seatNumber),
                          builder: (context, snapshot) {
                            final requests = snapshot.data;
                            final displayRequests =
                                requests != null && requests.isNotEmpty
                                ? requests
                                : List<RoomSeatRequestData>.generate(
                                    4,
                                    (index) => RoomSeatRequestData(
                                      id: index + 1,
                                      roomId: RoomSessionController
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
                              padding: EdgeInsets.symmetric(
                                horizontal: metrics.pageHorizontalPadding(
                                  compact: 12,
                                  regular: 16,
                                ),
                              ),
                              itemCount: displayRequests.length,
                              separatorBuilder: (context, index) => SizedBox(
                                height: metrics.spacing(20, min: 14, max: 20),
                              ),
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
    final metrics = ResponsiveMetrics.of(context);

    return SizedBox(
      height: metrics.spacing(40, min: 38, max: 44),
      child: Row(
        children: [
          Container(
            width: metrics.spacing(40, min: 38, max: 44),
            height: metrics.spacing(40, min: 38, max: 44),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x14285F98),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/room_small_mic_icon.png',
              width: metrics.spacing(20, min: 18, max: 22),
              height: metrics.spacing(20, min: 18, max: 22),
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(width: metrics.spacing(12, min: 10, max: 20)),
          Container(
            width: metrics.spacing(40, min: 38, max: 44),
            height: metrics.spacing(40, min: 38, max: 44),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x14285F98),
            ),
            alignment: Alignment.center,
            child: Text(
              '$seatNumber',
              style: TextStyle(
                color: Color(0xFF285F98),
                fontSize: metrics.font(16, min: 14, max: 17),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: metrics.spacing(12, min: 10, max: 20)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                name,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: metrics.font(12, min: 11, max: 13),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: metrics.spacing(12, min: 10, max: 20)),
          Container(
            width: metrics.spacing(40, min: 38, max: 44),
            height: metrics.spacing(40, min: 38, max: 44),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ResolvedImage(path: avatarAsset, fit: BoxFit.cover),
          ),
          SizedBox(width: metrics.spacing(10, min: 8, max: 14)),
          SizedBox(
            width: metrics.spacing(12, min: 10, max: 14),
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF285F98),
                fontSize: metrics.font(15, min: 13, max: 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
