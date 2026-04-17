import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/room_session_controller.dart';

Future<void> showRoomRequestMicSheet(
  BuildContext context, {
  required int seatNumber,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-request-mic-dialog',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _RoomRequestMicDialog(seatNumber: seatNumber);
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

class _RoomRequestMicDialog extends StatelessWidget {
  const _RoomRequestMicDialog({required this.seatNumber});

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
            label: 'room-request-mic-sheet',
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 176,
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
                    const SizedBox(height: 29),
                    Semantics(
                      container: true,
                      label: 'room-request-mic-confirm',
                      button: true,
                      child: ExcludeSemantics(
                        child: InkWell(
                          onTap: () async {
                            await RoomSessionController.instance.submitMicRequest(
                              seatNumber,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const SizedBox(
                            height: 46,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                'تقدم بطلب للحصول علي المايك',
                                textAlign: TextAlign.center,
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
                    const Spacer(),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE9E9E9),
                    ),
                    Semantics(
                      container: true,
                      label: 'room-request-mic-cancel',
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
