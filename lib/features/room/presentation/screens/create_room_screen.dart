import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../auth/data/auth_flow_store.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/room_repository.dart';
import 'room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _mutedBlue = Color(0xFFD2D9E3);
  static const Color _background = Color(0xFFF6F6F6);
  static const List<String> _roomTypes = <String>[
    'دردشة',
    'غناء',
    'حب',
    'عائلة',
    'مزيكا',
  ];
  static const List<String> _countries = <String>[
    'مصر',
    'السعودية',
    'الإمارات',
    'الكويت',
    'العراق',
    'المغرب',
  ];

  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController(
    text: 'ابحث عن شخص يمكنه الدردشه معي هالحين',
  );

  String _selectedRoomType = 'غناء';
  String _selectedCountry = 'مصر';
  RoomImageDraft? _cardImageDraft;
  String _selectedCardImageAsset = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = AuthFlowStore.instance.currentUser;
    final nickname = user?['nickname']?.toString().trim() ?? '';
    _roomNameController.text = nickname.isEmpty
        ? 'غرفة Hallo Party'
        : 'غرفة $nickname';
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  Future<void> _pickRoomImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
    );

    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCardImageAsset = '';
      _cardImageDraft = RoomImageDraft(
        fileName: pickedFile.name,
        mimeType: _mimeTypeForFileName(pickedFile.name),
        bytes: bytes,
      );
    });
  }

  String _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _pickCountry() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              shrinkWrap: true,
              children: _countries.map((country) {
                final isSelected = country == _selectedCountry;
                return ListTile(
                  title: Text(
                    country,
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: _primaryBlue)
                      : null,
                  onTap: () => Navigator.of(context).pop(country),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCountry = selection;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final roomName = _roomNameController.text.trim();
    final slogan = _sloganController.text.trim();
    if (roomName.isEmpty) {
      _showSnackBar('اسم الغرفة مطلوب');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final room = await RoomRepository.instance.createRoom(
        roomName: roomName,
        roomType: _selectedRoomType,
        sloganText: slogan,
        countryLabel: _selectedCountry,
        cardImageAsset: _selectedCardImageAsset,
        cardImageDraft: _cardImageDraft,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.room,
        arguments: RoomScreenArgs(roomId: room.id),
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final horizontalPadding = metrics.pageHorizontalPadding();
    final contentMaxWidth = metrics.maxContentWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: _background,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    metrics.spacing(56, min: 44, max: 64),
                    horizontalPadding,
                    metrics.spacing(28, min: 24, max: 32),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'انشاء غرفتي',
                              key: const ValueKey('create-room-title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: metrics.font(16, min: 15, max: 18),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: metrics.spacing(28, min: 24)),
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _RoomImagePreview(
                                    draft: _cardImageDraft,
                                    assetPath: _selectedCardImageAsset,
                                    size: metrics
                                        .size(80)
                                        .clamp(74, 92)
                                        .toDouble(),
                                  ),
                                  PositionedDirectional(
                                    bottom: -2,
                                    end: -2,
                                    child: InkWell(
                                      key: const ValueKey(
                                        'create-room-image-button',
                                      ),
                                      onTap: _pickRoomImage,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: metrics
                                            .size(24)
                                            .clamp(24, 28)
                                            .toDouble(),
                                        height: metrics
                                            .size(24)
                                            .clamp(24, 28)
                                            .toDouble(),
                                        decoration: const BoxDecoration(
                                          color: _primaryBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: metrics.spacing(18, min: 16)),
                            Text(
                              'نوع الغرفة',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: metrics.font(16, min: 15, max: 18),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: metrics.spacing(14, min: 12)),
                            Wrap(
                              spacing: metrics.spacing(14, min: 10, max: 16),
                              runSpacing: metrics.spacing(16, min: 12, max: 18),
                              alignment: WrapAlignment.end,
                              children: _roomTypes.map((type) {
                                final isSelected = type == _selectedRoomType;
                                return _RoomTypeChip(
                                  label: type,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedRoomType = type;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            SizedBox(height: metrics.spacing(18, min: 16)),
                            Text(
                              'اسم الغرفة',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: metrics.font(16, min: 15, max: 18),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: metrics.spacing(10, min: 8)),
                            _CreateRoomField(
                              key: const ValueKey('create-room-name-field'),
                              controller: _roomNameController,
                              hintText: 'غرفة Mohamed',
                            ),
                            SizedBox(height: metrics.spacing(16, min: 14)),
                            Text(
                              'شعار الغرفة',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: metrics.font(16, min: 15, max: 18),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: metrics.spacing(10, min: 8)),
                            _CreateRoomField(
                              key: const ValueKey('create-room-slogan-field'),
                              controller: _sloganController,
                              hintText: 'ابحث عن شخص يمكنه الدردشه معي هالحين',
                            ),
                            SizedBox(height: metrics.spacing(16, min: 14)),
                            Text(
                              'اختار بلد',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: metrics.font(16, min: 15, max: 18),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: metrics.spacing(10, min: 8)),
                            _CountrySelector(
                              key: const ValueKey(
                                'create-room-country-selector',
                              ),
                              countryLabel: _selectedCountry,
                              onTap: _pickCountry,
                            ),
                            SizedBox(
                              height: metrics.spacing(40, min: 30, max: 46),
                            ),
                            SizedBox(
                              height: metrics.size(36).clamp(36, 42).toDouble(),
                              child: ElevatedButton(
                                key: const ValueKey(
                                  'create-room-submit-button',
                                ),
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  _isSubmitting
                                      ? 'جاري الانشاء...'
                                      : 'انشاء غرفة',
                                  style: TextStyle(
                                    fontSize: metrics.font(
                                      12,
                                      min: 12,
                                      max: 14,
                                    ),
                                    fontWeight: FontWeight.w600,
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
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.home,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomImagePreview extends StatelessWidget {
  const _RoomImagePreview({
    required this.draft,
    required this.assetPath,
    required this.size,
  });

  final RoomImageDraft? draft;
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (draft != null) {
      child = Image.memory(
        draft!.bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (assetPath.isNotEmpty) {
      child = ResolvedImage(path: assetPath, width: size, height: size);
    } else {
      child = Container(
        width: size,
        height: size,
        color: _CreateRoomScreenState._primaryBlue,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: size * 0.07,
              child: Container(
                width: size * 0.74,
                height: size * 0.40,
                decoration: BoxDecoration(
                  color: const Color(0xFF9DB2CE),
                  borderRadius: BorderRadius.circular(size * 0.18),
                ),
              ),
            ),
            Positioned(
              top: size * 0.17,
              child: Container(
                width: size * 0.38,
                height: size * 0.38,
                decoration: const BoxDecoration(
                  color: Color(0xFF9DB2CE),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.4),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class _RoomTypeChip extends StatelessWidget {
  const _RoomTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: metrics.size(79).clamp(76, 92).toDouble(),
        height: metrics.size(29).clamp(29, 34).toDouble(),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? _CreateRoomScreenState._primaryBlue
              : _CreateRoomScreenState._mutedBlue,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : _CreateRoomScreenState._primaryBlue,
            fontSize: metrics.font(10, min: 10, max: 11),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CreateRoomField extends StatelessWidget {
  const _CreateRoomField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Container(
      height: metrics.size(36).clamp(36, 42).toDouble(),
      decoration: BoxDecoration(
        color: _CreateRoomScreenState._mutedBlue,
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _CreateRoomScreenState._primaryBlue,
          fontSize: metrics.font(10, min: 10, max: 11),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: _CreateRoomScreenState._primaryBlue,
            fontSize: metrics.font(10, min: 10, max: 11),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: metrics.spacing(14, min: 12, max: 16),
            vertical: metrics.spacing(12, min: 10, max: 12),
          ),
        ),
      ),
    );
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({
    super.key,
    required this.countryLabel,
    required this.onTap,
  });

  final String countryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: metrics.size(36).clamp(36, 42).toDouble(),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.spacing(14, min: 12, max: 16),
        ),
        decoration: BoxDecoration(
          color: _CreateRoomScreenState._mutedBlue,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _CreateRoomScreenState._primaryBlue,
            ),
            const Spacer(),
            Text(
              countryLabel,
              style: TextStyle(
                color: _CreateRoomScreenState._primaryBlue,
                fontSize: metrics.font(10, min: 10, max: 11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
