import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/club_repository.dart';
import 'home_clubs_screen.dart';

class HomeClubCreateScreen extends StatefulWidget {
  const HomeClubCreateScreen({super.key});

  @override
  State<HomeClubCreateScreen> createState() => _HomeClubCreateScreenState();
}

class _HomeClubCreateScreenState extends State<HomeClubCreateScreen> {
  static const int _nameLimit = 20;
  static const int _codeLimit = 20;
  static const int _announcementLimit = 500;
  static const int _creationCostDiamonds = 500000;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ClubImageDraft? _avatarDraft;
  Uint8List? _avatarPreviewBytes;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_rebuildCounters);
    _codeController.addListener(_rebuildCounters);
    _announcementController.addListener(_rebuildCounters);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_rebuildCounters)
      ..dispose();
    _codeController
      ..removeListener(_rebuildCounters)
      ..dispose();
    _announcementController
      ..removeListener(_rebuildCounters)
      ..dispose();
    super.dispose();
  }

  void _rebuildCounters() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAvatar() async {
    if (_isPickingImage) {
      return;
    }
    setState(() {
      _isPickingImage = true;
    });
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 86,
      );
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarPreviewBytes = bytes;
        _avatarDraft = ClubImageDraft(
          fileName: image.name,
          mimeType: _mimeTypeFor(image),
          bytes: bytes,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  String _mimeTypeFor(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) {
      return mimeType;
    }
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await ClubRepository.instance.createClub(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        announcementText: _announcementController.text.trim(),
        avatarDraft: _avatarDraft,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), textDirection: TextDirection.rtl),
        ),
      );
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HomeClubsScreen.background,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 28),
              children: [
                _CreateHeader(onBack: () => Navigator.of(context).pop(false)),
                const SizedBox(height: 28),
                _ClubAvatarPicker(
                  previewBytes: _avatarPreviewBytes,
                  isPicking: _isPickingImage,
                  onTap: _pickAvatar,
                ),
                const SizedBox(height: 32),
                _FieldLabel(label: 'اسم النادي'),
                const SizedBox(height: 8),
                _ClubTextField(
                  key: const ValueKey('home-club-create-name-field'),
                  controller: _nameController,
                  hintText: 'لآ يتجاوز عن 20 حرف',
                  helperText: 'اسم النادي الخاص بك',
                  maxLength: _nameLimit,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'اكتب اسم النادي';
                    }
                    if (text.length > _nameLimit) {
                      return 'اسم النادي لا يتجاوز 20 حرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _FieldLabel(label: 'رمز النادي'),
                const SizedBox(height: 8),
                _ClubTextField(
                  key: const ValueKey('home-club-create-code-field'),
                  controller: _codeController,
                  hintText: 'لا يتجاوز عن 20 حرف',
                  helperText: 'ضع علامة علي ناديك',
                  maxLength: _codeLimit,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'اكتب رمز النادي';
                    }
                    if (!RegExp(
                      r'^[A-Za-z0-9_\-\u0600-\u06FF]+$',
                    ).hasMatch(text)) {
                      return 'استخدم حروف أو أرقام فقط';
                    }
                    if (text.length > _codeLimit) {
                      return 'رمز النادي لا يتجاوز 20 حرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _FieldLabel(label: 'إعلان النادي'),
                const SizedBox(height: 8),
                _ClubTextField(
                  key: const ValueKey('home-club-create-announcement-field'),
                  controller: _announcementController,
                  hintText: 'اكتب اعلانا ناديك',
                  helperText: '',
                  maxLength: _announcementLimit,
                  maxLines: 5,
                  validator: (value) {
                    if ((value?.length ?? 0) > _announcementLimit) {
                      return 'الإعلان لا يتجاوز 500 حرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const _ClubNote(),
                const SizedBox(height: 18),
                const _ClubGuidelines(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 57,
                  child: ElevatedButton(
                    key: const ValueKey('home-club-create-submit-button'),
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeClubsScreen.primaryBlue,
                      disabledBackgroundColor: const Color(0xFF9CB6D1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'دفع $_creationCostDiamonds الماس لاتمام انشاء النادي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
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
  }
}

class _CreateHeader extends StatelessWidget {
  const _CreateHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: HomeClubsScreen.primaryBlue,
              size: 17,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'انشئ نادى',
          key: ValueKey('home-club-create-title'),
          style: TextStyle(
            color: HomeClubsScreen.primaryBlue,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 34),
      ],
    );
  }
}

class _ClubAvatarPicker extends StatelessWidget {
  const _ClubAvatarPicker({
    required this.previewBytes,
    required this.isPicking,
    required this.onTap,
  });

  final Uint8List? previewBytes;
  final bool isPicking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: isPicking ? null : onTap,
        borderRadius: BorderRadius.circular(27),
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 83,
                height: 83,
                decoration: BoxDecoration(
                  color: HomeClubsScreen.primaryBlue,
                  borderRadius: BorderRadius.circular(27),
                ),
                clipBehavior: Clip.antiAlias,
                child: previewBytes == null
                    ? const Icon(
                        Icons.groups_2_rounded,
                        color: HomeClubsScreen.lightBlue,
                        size: 54,
                      )
                    : Image.memory(previewBytes!, fit: BoxFit.cover),
              ),
              Positioned(
                left: 9,
                bottom: 10,
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: const BoxDecoration(
                    color: HomeClubsScreen.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: isPicking
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: HomeClubsScreen.primaryBlue,
        fontSize: 23,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ClubTextField extends StatelessWidget {
  const _ClubTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.helperText,
    required this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hintText;
  final String helperText;
  final int maxLength;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          validator: validator,
          textCapitalization: textCapitalization,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: HomeClubsScreen.primaryBlue,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: HomeClubsScreen.primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            counterText: '',
            filled: true,
            fillColor: HomeClubsScreen.softField,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: maxLines > 1 ? 16 : 17,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (helperText.isNotEmpty)
              Expanded(
                child: Text(
                  helperText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: HomeClubsScreen.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const Spacer(),
            Text(
              '${controller.text.length}/$maxLength',
              style: const TextStyle(
                color: HomeClubsScreen.primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClubNote extends StatelessWidget {
  const _ClubNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'الملاحظات: رمز النادي هو اسم النادي المختصر وسيتم عرضه في غرف النادي واعضاء النادى.',
        textAlign: TextAlign.right,
        style: TextStyle(
          color: HomeClubsScreen.primaryBlue,
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClubGuidelines extends StatelessWidget {
  const _ClubGuidelines();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'استعدعي:\n'
      '1. عندما يصنف ناديك في اعلي 150 من القائمة الشهرية، يمكن للنادي الحصول علي المكافات.\n'
      '2. عدد التغييرات التي يتم إجراؤها علي الصور الرمزية للنادي والأسماء والعلامات محدود لذلك لا تقم بتغييرها بشكل عشوائي.\n'
      '3. اذا كان مستوي الثروة اكبر من مستوي 35، فيمكنك انشاء نادي مجانأ.',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: HomeClubsScreen.primaryBlue,
        fontSize: 13,
        height: 1.65,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
