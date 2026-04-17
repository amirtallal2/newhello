import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/room_session_controller.dart';
import '../widgets/room_background_view.dart';
import 'room_settings_screen.dart';

class RoomMicQuantityScreen extends StatefulWidget {
  const RoomMicQuantityScreen({super.key});

  static const Color _modalTop = Color(0xFF7FBAF8);
  static const Color _modalBottom = Color(0xFF285F98);
  static const Color _cardStart = Color(0xFF285F98);
  static const Color _cardEnd = Color(0xFF065FBD);
  static const Color _selectedBorder = Color(0xFF92F8C4);
  static const Color _micCircle = Color(0xFF9DB2CE);
  static const Color _saveGreen = Color(0xFF1F9254);

  @override
  State<RoomMicQuantityScreen> createState() => _RoomMicQuantityScreenState();
}

class _RoomMicQuantityScreenState extends State<RoomMicQuantityScreen> {
  late int _selectedMicCount;

  static const List<_MicCountOption> _options = [
    _MicCountOption(label: '9 ميكروفون', count: 9, rows: [1, 4, 4]),
    _MicCountOption(label: '5 ميكروفون', count: 5, rows: [1, 4]),
    _MicCountOption(label: '15 ميكروفون', count: 15, rows: [5, 5, 5]),
    _MicCountOption(label: '12 ميكروفون', count: 12, rows: [2, 5, 5]),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMicCount = RoomSessionController.instance.micCount.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoomBackgroundView(),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: const SizedBox.expand(),
            ),
          ),
          RoomSettingsBackdrop(
            onGeneralActionTap: (label) {
              if (label == 'اعدادات الغرفة') {
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.roomGeneralSettings);
                return;
              }

              if (label == 'صورة الخلفية') {
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.roomBackgroundSelection);
                return;
              }

              if (label == 'كمية الميكروفون') {
                return;
              }

              Navigator.of(context).pushNamed(AppRoutes.bootstrap);
            },
            onRoomModeTap: (_) {
              Navigator.of(context).pushNamed(AppRoutes.bootstrap);
            },
            onMoreActionTap: (label) {
              if (label == 'تصغير الشاشة') {
                Navigator.of(context).pop();
                return;
              }

              Navigator.of(context).pushNamed(AppRoutes.bootstrap);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 209,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 332),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _MicQuantityModal(
                    options: _options,
                    selectedMicCount: _selectedMicCount,
                    onOptionTap: (count) {
                      final previousMicCount = _selectedMicCount;
                      setState(() {
                        _selectedMicCount = count;
                      });
                      RoomSessionController.instance
                          .persistMicCount(count)
                          .catchError((_) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _selectedMicCount = previousMicCount;
                            });
                            RoomSessionController.instance.updateMicCount(
                              previousMicCount,
                            );
                          });
                    },
                    onSaveTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 18,
            bottom: 22,
            child: RoomSettingsBottomComposer(
              onControlTap: () {},
              onMuteTap: () {
                Navigator.of(context).pushNamed(AppRoutes.bootstrap);
              },
              onChatTap: () {
                Navigator.of(context).pushNamed(AppRoutes.bootstrap);
              },
              onGiftTap: () {
                Navigator.of(context).pushNamed(AppRoutes.bootstrap);
              },
              onSendTap: () {
                Navigator.of(context).pushNamed(AppRoutes.bootstrap);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MicQuantityModal extends StatelessWidget {
  const _MicQuantityModal({
    required this.options,
    required this.selectedMicCount,
    required this.onOptionTap,
    required this.onSaveTap,
  });

  final List<_MicCountOption> options;
  final int selectedMicCount;
  final ValueChanged<int> onOptionTap;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 10, 17, 23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RoomMicQuantityScreen._modalTop,
            RoomMicQuantityScreen._modalBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'كمية المايكات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MicOptionTile(
                  option: options[0],
                  isSelected: selectedMicCount == options[0].count,
                  onTap: () => onOptionTap(options[0].count),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _MicOptionTile(
                  option: options[1],
                  isSelected: selectedMicCount == options[1].count,
                  onTap: () => onOptionTap(options[1].count),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MicOptionTile(
                  option: options[2],
                  isSelected: selectedMicCount == options[2].count,
                  onTap: () => onOptionTap(options[2].count),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _MicOptionTile(
                  option: options[3],
                  isSelected: selectedMicCount == options[3].count,
                  onTap: () => onOptionTap(options[3].count),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onSaveTap,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 33,
              decoration: BoxDecoration(
                color: RoomMicQuantityScreen._saveGreen,
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: const Text(
                'حفظ التغيرات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicOptionTile extends StatelessWidget {
  const _MicOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _MicCountOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 103,
            padding: const EdgeInsets.fromLTRB(13, 15, 13, 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  RoomMicQuantityScreen._cardStart,
                  RoomMicQuantityScreen._cardEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: RoomMicQuantityScreen._selectedBorder)
                  : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _MicPattern(rows: option.rows),
                    ),
                  ),
                ),
                if (isSelected)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/images/room_selected_check_icon.png',
                      width: 15,
                      height: 15,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            option.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MicPattern extends StatelessWidget {
  const _MicPattern({required this.rows});

  final List<int> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rows.length,
        (rowIndex) => Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rows.length - 1 ? 0 : 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              rows[rowIndex],
              (index) => Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: RoomMicQuantityScreen._micCircle,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/room_mic_dot_icon.png',
                    width: 10,
                    height: 10,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicCountOption {
  const _MicCountOption({
    required this.label,
    required this.count,
    required this.rows,
  });

  final String label;
  final int count;
  final List<int> rows;
}
