import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  String _displayName = 'بسملة محمد';
  String _birthDate = '2004/09/20';
  String _country = 'Egypt';

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _background = Color(0xFFF6F6F6);
  static const Color _photoPlaceholder = Color(0x80C9D9EE);

  static const List<_PhotoTileData> _photoTiles = [
    _PhotoTileData(imageAsset: 'assets/images/profile_edit_photo_primary.png'),
    _PhotoTileData(levelLabel: 'Lv15'),
    _PhotoTileData(levelLabel: 'Lv25'),
    _PhotoTileData(levelLabel: 'Lv35'),
    _PhotoTileData(levelLabel: 'Lv50'),
    _PhotoTileData(levelLabel: 'Lv50'),
  ];

  List<_EditableFieldData> get _fields => [
    _EditableFieldData(
      label: 'الاسم',
      value: _displayName,
      showEditButton: true,
    ),
    const _EditableFieldData(
      label: 'جنس',
      value: 'غير قابل للتعديل',
      isEditable: false,
      showArrow: false,
    ),
    const _EditableFieldData(
      label: 'عيد ميلاد',
      value: '',
      showEditButton: true,
    ),
    const _EditableFieldData(
      label: 'الدولة الخاصة بك',
      value: '',
      showEditButton: true,
    ),
    const _EditableFieldData(
      label: 'توقيع شخصي',
      value: 'ليس لديك المقدمة الشخصية',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(17, 46, 17, 22),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Semantics(
                              label: 'profile-edit-back',
                              button: true,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(19),
                                child: Container(
                                  width: 38,
                                  height: 37,
                                  decoration: const BoxDecoration(
                                    color: _lightBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _primaryBlue,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'التحرير',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 38),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const _PhotoGrid(),
                        const SizedBox(height: 30),
                        ..._fields.map((field) {
                          final resolvedField = switch (field.label) {
                            'عيد ميلاد' => field.copyWith(value: _birthDate),
                            'الدولة الخاصة بك' => field.copyWith(
                              value: _country,
                            ),
                            _ => field,
                          };

                          return _EditableFieldRow(
                            data: resolvedField,
                            onTap: resolvedField.isEditable
                                ? () {
                                    if (resolvedField.label == 'الاسم') {
                                      _showEditNameDialog();
                                      return;
                                    }

                                    if (resolvedField.label == 'عيد ميلاد') {
                                      _showEditBirthDateDialog();
                                      return;
                                    }

                                    if (resolvedField.label ==
                                        'الدولة الخاصة بك') {
                                      _showEditCountryDialog();
                                      return;
                                    }

                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.bootstrap);
                                  }
                                : null,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const MainBottomNavigation(
              currentTab: MainBottomNavigationTab.profile,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _displayName);

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x295D5D5D),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 31),
          child: Center(
            child: Container(
              width: 312,
              padding: const EdgeInsets.fromLTRB(27, 15, 27, 29),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'الاسم',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        key: const ValueKey('profile-name-dialog-input'),
                        controller: controller,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        key: const ValueKey('profile-name-dialog-confirm'),
                        onPressed: () {
                          setState(() {
                            final newValue = controller.text.trim();
                            if (newValue.isNotEmpty) {
                              _displayName = newValue;
                            }
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'تاكيد التغير',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditBirthDateDialog() async {
    final controller = TextEditingController(text: _birthDate);

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x295D5D5D),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 31),
          child: Center(
            child: Container(
              width: 312,
              padding: const EdgeInsets.fromLTRB(27, 15, 27, 29),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'عيد الميلاد',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        key: const ValueKey('profile-birthdate-dialog-input'),
                        controller: controller,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        key: const ValueKey('profile-birthdate-dialog-confirm'),
                        onPressed: () {
                          setState(() {
                            final newValue = controller.text.trim();
                            if (newValue.isNotEmpty) {
                              _birthDate = newValue;
                            }
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'تاكيد التغير',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditCountryDialog() async {
    final controller = TextEditingController(text: _country);

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x295D5D5D),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 31),
          child: Center(
            child: Container(
              width: 312,
              padding: const EdgeInsets.fromLTRB(27, 15, 27, 29),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'الدولة',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        key: const ValueKey('profile-country-dialog-input'),
                        controller: controller,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        key: const ValueKey('profile-country-dialog-confirm'),
                        onPressed: () {
                          setState(() {
                            final newValue = controller.text.trim();
                            if (newValue.isNotEmpty) {
                              _country = newValue;
                            }
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'تاكيد التغير',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: _ProfileEditScreenState._photoTiles
          .map((tile) => _PhotoTile(data: tile))
          .toList(),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.data});

  final _PhotoTileData data;

  @override
  Widget build(BuildContext context) {
    final hasImage = data.imageAsset != null;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: hasImage ? null : _ProfileEditScreenState._photoPlaceholder,
            borderRadius: BorderRadius.circular(5),
            image: hasImage
                ? DecorationImage(
                    image: AssetImage(data.imageAsset!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: hasImage
              ? null
              : const Text(
                  '+',
                  style: TextStyle(
                    color: _ProfileEditScreenState._primaryBlue,
                    fontSize: 35,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
        ),
        if (data.levelLabel != null)
          PositionedDirectional(
            top: 5,
            start: 5,
            child: Container(
              width: 30,
              height: 15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF285F98), Color(0xFF5097F5)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                data.levelLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EditableFieldRow extends StatelessWidget {
  const _EditableFieldRow({required this.data, this.onTap});

  final _EditableFieldData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            data.label,
            style: const TextStyle(
              color: _ProfileEditScreenState._primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              data.value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: _ProfileEditScreenState._primaryBlue,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (data.showEditButton) ...[
            const SizedBox(width: 12),
            _InlineEditButton(label: data.label, onTap: onTap),
          ],
          if (data.showArrow) ...[
            const SizedBox(width: 15),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 12,
              color: _ProfileEditScreenState._primaryBlue,
            ),
          ],
        ],
      ),
    );

    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}

class _InlineEditButton extends StatelessWidget {
  const _InlineEditButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-inline-edit-$label',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _ProfileEditScreenState._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 10),
        ),
      ),
    );
  }
}

class _PhotoTileData {
  const _PhotoTileData({this.imageAsset, this.levelLabel});

  final String? imageAsset;
  final String? levelLabel;
}

class _EditableFieldData {
  const _EditableFieldData({
    required this.label,
    required this.value,
    this.isEditable = true,
    this.showArrow = true,
    this.showEditButton = false,
  });

  final String label;
  final String value;
  final bool isEditable;
  final bool showArrow;
  final bool showEditButton;

  _EditableFieldData copyWith({
    String? label,
    String? value,
    bool? isEditable,
    bool? showArrow,
    bool? showEditButton,
  }) {
    return _EditableFieldData(
      label: label ?? this.label,
      value: value ?? this.value,
      isEditable: isEditable ?? this.isEditable,
      showArrow: showArrow ?? this.showArrow,
      showEditButton: showEditButton ?? this.showEditButton,
    );
  }
}
