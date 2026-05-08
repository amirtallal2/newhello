import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/post_repository.dart';

final class PostCreateScreenArgs {
  const PostCreateScreenArgs({this.editPost});

  final PostItemData? editPost;
}

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key, this.args = const PostCreateScreenArgs()});

  final PostCreateScreenArgs args;

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _background = Color(0xFFF6F6F6);

  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final PostRepository _repository = PostRepository.instance;

  PostImageDraft? _selectedImage;
  String? _existingImagePath;
  bool _removeExistingImage = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.args.editPost != null;

  @override
  void initState() {
    super.initState();
    final editPost = widget.args.editPost;
    if (editPost != null) {
      _postController.text = editPost.bodyText;
      _existingImagePath = editPost.imagePath;
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 70, 17, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: 'post-create-back',
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
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _isEditMode ? 'تعديل المنشور' : 'نشر لحظات',
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _isEditMode
                              ? 'عدل النص أو الصورة واحفظ المنشور كما يجب'
                              : 'نشر الاخبار ، والتعرف علي المزيد من الناس متعة',
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _postController,
                          builder: (context, value, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const ValueKey('post-create-editor'),
                                    controller: _postController,
                                    maxLength: 1000,
                                    maxLines: null,
                                    expands: true,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText:
                                          'اكتب نص المنشور أو اتركه فارغًا لو الصورة كافية',
                                      border: InputBorder.none,
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    '${value.text.characters.length}/1000',
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ImageComposer(
                        selectedImage: _selectedImage,
                        existingImagePath: _removeExistingImage
                            ? null
                            : _existingImagePath,
                        onPickTap: _pickImage,
                        onRemoveTap: _removeImage,
                      ),
                      const SizedBox(height: 38),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          key: const ValueKey('post-create-submit'),
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
                                ? (_isEditMode
                                      ? 'جارٍ الحفظ...'
                                      : 'جارٍ النشر...')
                                : (_isEditMode
                                      ? 'حفظ التعديل'
                                      : 'نشر البوست الان'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
            const _ComposerBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = PostImageDraft(
        fileName: file.name,
        mimeType: _inferMimeType(file.name),
        bytes: bytes,
      );
      _removeExistingImage = false;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      if (_existingImagePath != null) {
        _removeExistingImage = true;
      }
    });
  }

  Future<void> _submit() async {
    final bodyText = _postController.text.trim();
    final hasImage =
        _selectedImage != null ||
        (!_removeExistingImage &&
            _existingImagePath != null &&
            _existingImagePath!.trim().isNotEmpty);
    if (bodyText.isEmpty && !hasImage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتب نصًا أو اختر صورة.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final PostItemData savedPost;
      final editPost = widget.args.editPost;
      if (editPost == null) {
        savedPost = await _repository.createPost(
          bodyText: bodyText,
          image: _selectedImage,
        );
      } else {
        savedPost = await _repository.updatePost(
          postId: editPost.id,
          bodyText: bodyText,
          image: _selectedImage,
          removeImage: _removeExistingImage,
        );
      }

      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(savedPost);
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.post, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class _ImageComposer extends StatelessWidget {
  const _ImageComposer({
    required this.selectedImage,
    required this.existingImagePath,
    required this.onPickTap,
    required this.onRemoveTap,
  });

  final PostImageDraft? selectedImage;
  final String? existingImagePath;
  final VoidCallback onPickTap;
  final VoidCallback onRemoveTap;

  bool get _hasImage =>
      selectedImage != null ||
      (existingImagePath != null && existingImagePath!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            label: 'post-create-add-image',
            button: true,
            child: InkWell(
              onTap: onPickTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: _hasImage ? double.infinity : 85,
                height: _hasImage ? 170 : 85,
                decoration: BoxDecoration(
                  color: _PostCreateScreenState._lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: _imagePreview(),
              ),
            ),
          ),
          if (_hasImage) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                TextButton.icon(
                  onPressed: onPickTap,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('تغيير الصورة'),
                  style: TextButton.styleFrom(
                    foregroundColor: _PostCreateScreenState._primaryBlue,
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemoveTap,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('حذف الصورة'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB45A5A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagePreview() {
    final selected = selectedImage;
    if (selected != null) {
      return Image.memory(
        selected.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final existing = existingImagePath;
    if (existing != null && existing.trim().isNotEmpty) {
      return ResolvedImage(
        path: existing,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return const Text(
      '+',
      style: TextStyle(
        color: _PostCreateScreenState._primaryBlue,
        fontSize: 48,
        fontWeight: FontWeight.w400,
        height: 1,
      ),
    );
  }
}

class _ComposerBottomNavigation extends StatelessWidget {
  const _ComposerBottomNavigation();

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _inactive = Color(0xFF9DB2CE);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 77,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ComposerBottomNavItem(
              label: 'الرئيسية',
              icon: Icons.home_rounded,
              color: _inactive,
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
              },
            ),
            _ComposerBottomNavItem(
              label: 'الدردشة',
              icon: Icons.chat_bubble_outline_rounded,
              color: _inactive,
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.chatInbox,
                  (route) => false,
                );
              },
            ),
            _ComposerBottomNavItem(
              label: 'المنشورات',
              icon: Icons.add_circle_outline_rounded,
              color: _primaryBlue,
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.post, (route) => false);
              },
            ),
            _ComposerBottomNavItem(
              label: 'الملف',
              icon: Icons.person_outline_rounded,
              color: _inactive,
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.profile, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerBottomNavItem extends StatelessWidget {
  const _ComposerBottomNavItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
