import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/profile_support_repository.dart';

class ProfileSupportCenterScreen extends StatefulWidget {
  const ProfileSupportCenterScreen({super.key});

  @override
  State<ProfileSupportCenterScreen> createState() =>
      _ProfileSupportCenterScreenState();
}

class _ProfileSupportCenterScreenState
    extends State<ProfileSupportCenterScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _inactiveBlue = Color(0xFF9DB2CE);

  final ProfileSupportRepository _repository =
      ProfileSupportRepository.instance;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<SupportAttachmentDraft?> _attachments =
      List<SupportAttachmentDraft?>.filled(3, null);

  String _selectedCategory = 'اعادة الشحن';
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'مشكلة تطبيق',
    'الاقتراحات',
    'اخري',
    'اعادة الشحن',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: 'profile-support-back',
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
                              color: Color(0xFFB4D1EF),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: _primaryBlue,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'مركز الدعم الفني',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 25,
                        runSpacing: 20,
                        children: _categories
                            .map(
                              (category) => _SupportCategoryChip(
                                label: category,
                                isSelected: _selectedCategory == category,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 30),
                      const _SectionTitle('الرجاء وصف المشكلة بالكامل !'),
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الرجاء كتابة الوصف بالكامل لحل مشكلتك في اقرب وقت ممكن',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 96,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextField(
                          key: const ValueKey('profile-support-description'),
                          controller: _descriptionController,
                          maxLength: 300,
                          maxLines: null,
                          expands: true,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_descriptionController.text.characters.length}/300',
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(
                        'الرجاء ارسال لقطة من الشاشة لحل المشكلة ! (اختياري)',
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List<Widget>.generate(3, (index) {
                          return _UploadPlaceholder(
                            index: index + 1,
                            attachment: _attachments[index],
                            onTap: () => _pickAttachment(index),
                          );
                        }).reversed.toList(),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 275,
                          height: 38,
                          child: ElevatedButton(
                            key: const ValueKey('profile-support-submit'),
                            onPressed: _isSubmitting ? null : _submitTicket,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _isSubmitting
                                  ? 'جارٍ ارسال المشكلة...'
                                  : 'ارسال الان المشكلة',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachment(int index) async {
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
      _attachments[index] = SupportAttachmentDraft(
        fileName: file.name,
        mimeType: _inferMimeType(file.name),
        bytes: bytes,
      );
    });
  }

  Future<void> _submitTicket() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب وصف المشكلة أولًا.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final receipt = await _repository.submitSupportTicket(
        category: _selectedCategory,
        description: description,
        attachments: _attachments.whereType<SupportAttachmentDraft>().toList(),
      );

      if (!mounted) {
        return;
      }

      _descriptionController.clear();
      setState(() {
        for (var index = 0; index < _attachments.length; index++) {
          _attachments[index] = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال التذكرة بنجاح: ${receipt.ticketCode}',
          ),
        ),
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

  String _inferMimeType(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }
}

class _SupportCategoryChip extends StatelessWidget {
  const _SupportCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-support-category-$label',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 145,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? _ProfileSupportCenterScreenState._primaryBlue
                : _ProfileSupportCenterScreenState._inactiveBlue,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : _ProfileSupportCenterScreenState._primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.white,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({
    required this.index,
    required this.attachment,
    required this.onTap,
  });

  final int index;
  final SupportAttachmentDraft? attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-support-upload-$index',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 100,
          height: 100,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0x80C9D9EE),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: attachment == null
              ? const Text(
                  '+',
                  style: TextStyle(
                    color: _ProfileSupportCenterScreenState._primaryBlue,
                    fontSize: 35,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                )
              : Image.memory(
                  attachment!.bytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
      ),
    );
  }
}
