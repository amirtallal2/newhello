import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/profile_account_repository.dart';
import '../widgets/profile_decorated_avatar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _background = Color(0xFFF6F6F6);
  static const Color _photoPlaceholder = Color(0x80C9D9EE);
  static const List<_CountryOption> _countryOptions = [
    _CountryOption(label: 'مصر', flag: '🇪🇬'),
    _CountryOption(label: 'السعودية', flag: '🇸🇦'),
    _CountryOption(label: 'الإمارات', flag: '🇦🇪'),
    _CountryOption(label: 'الكويت', flag: '🇰🇼'),
    _CountryOption(label: 'قطر', flag: '🇶🇦'),
    _CountryOption(label: 'البحرين', flag: '🇧🇭'),
    _CountryOption(label: 'عمان', flag: '🇴🇲'),
    _CountryOption(label: 'الأردن', flag: '🇯🇴'),
    _CountryOption(label: 'فلسطين', flag: '🇵🇸'),
    _CountryOption(label: 'لبنان', flag: '🇱🇧'),
    _CountryOption(label: 'العراق', flag: '🇮🇶'),
    _CountryOption(label: 'المغرب', flag: '🇲🇦'),
    _CountryOption(label: 'الجزائر', flag: '🇩🇿'),
    _CountryOption(label: 'تونس', flag: '🇹🇳'),
    _CountryOption(label: 'ليبيا', flag: '🇱🇾'),
    _CountryOption(label: 'السودان', flag: '🇸🇩'),
    _CountryOption(label: 'تركيا', flag: '🇹🇷'),
    _CountryOption(label: 'الولايات المتحدة', flag: '🇺🇸'),
    _CountryOption(label: 'المملكة المتحدة', flag: '🇬🇧'),
  ];
  static const List<_PhotoTileData> _photoTiles = [
    _PhotoTileData(
      imageAsset: 'assets/images/profile_avatar.png',
      levelLabel: 'Lv15',
    ),
    _PhotoTileData(
      imageAsset: 'assets/images/post_author_avatar.png',
      levelLabel: 'Lv20',
    ),
    _PhotoTileData(
      imageAsset: 'assets/images/live150_comment_avatar.png',
      levelLabel: 'Lv25',
    ),
    _PhotoTileData(
      imageAsset: 'assets/images/profile_store_friend_yara.png',
      levelLabel: 'Lv35',
    ),
    _PhotoTileData(
      imageAsset: 'assets/images/profile_store_friend_yara_alt.png',
      levelLabel: 'Lv50',
    ),
    _PhotoTileData(
      imageAsset: 'assets/images/profile_store_friend_nona_avatar.png',
      levelLabel: 'Lv50',
    ),
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingAvatar = false;

  String _displayName = '';
  String _email = '';
  String _phone = '';
  String _birthDate = '';
  String _country = '';
  String _signatureText = '';
  String _profileHandle = '';
  String _avatarAsset = _photoTiles.first.imageAsset;
  String _gender = '';
  ProfileAppearanceData _appearance = const ProfileAppearanceData();

  List<_EditableFieldData> get _fields => [
    _EditableFieldData(
      label: 'الاسم',
      value: _displayName,
      showEditButton: true,
    ),
    _EditableFieldData(label: 'جنس', value: 'غير قابل للتعديل'),
    _EditableFieldData(
      label: 'عيد ميلاد',
      value: _birthDate.isEmpty ? 'غير محدد' : _displayBirthDate(_birthDate),
      showEditButton: true,
    ),
    _EditableFieldData(
      label: 'الدولة الخاصة بك',
      value: _country.isEmpty ? 'غير محدد' : _displayCountryLabel(_country),
      showEditButton: true,
    ),
    _EditableFieldData(
      label: 'توقيع شخصي',
      value: _signatureText.isEmpty
          ? 'ليس لديك المقدمة الشخصية'
          : _signatureText,
      showEditButton: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await ProfileAccountRepository.instance.loadSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _syncFromSummary(summary);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showError(error);
    }
  }

  void _syncFromSummary(ProfileSummaryData summary) {
    _displayName = summary.user.nickname;
    _email = summary.user.email ?? '';
    _phone = summary.user.phone ?? '';
    _birthDate = summary.user.birthdate ?? '';
    _country = summary.user.country;
    _signatureText = summary.user.signatureText;
    _profileHandle = summary.user.profileHandle;
    _avatarAsset = summary.user.avatarAsset;
    _gender = summary.user.gender?.trim() ?? '';
    _appearance = summary.appearance;
  }

  Future<void> _persistProfile({ProfileAvatarDraft? avatarDraft}) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final summary = await ProfileAccountRepository.instance.updateProfile(
        nickname: _displayName.trim(),
        email: _email.trim(),
        phone: _phone.trim(),
        birthdate: _normalizeBirthDateForApi(_birthDate.trim()),
        gender: _gender.trim(),
        country: _country.trim(),
        signatureText: _signatureText.trim(),
        profileHandle: _profileHandle.trim(),
        avatarAsset: _avatarAsset,
        avatarDraft: avatarDraft,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _syncFromSummary(summary);
      });
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _showEditDialog({
    required String title,
    required String initialValue,
    required String inputKey,
    required String confirmKey,
    required TextDirection textDirection,
    TextInputType? keyboardType,
    required void Function(String value) onConfirm,
  }) async {
    final controller = TextEditingController(text: initialValue);
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x295D5D5D),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        Text(
                          title,
                          style: const TextStyle(
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
                            key: ValueKey(inputKey),
                            controller: controller,
                            textAlign: TextAlign.center,
                            textDirection: textDirection,
                            keyboardType: keyboardType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton(
                            key: ValueKey(confirmKey),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final newValue = controller.text.trim();
                                    setDialogState(() {
                                      isSubmitting = true;
                                    });
                                    try {
                                      onConfirm(newValue);
                                      await _persistProfile();
                                      if (!dialogContext.mounted) {
                                        return;
                                      }
                                      Navigator.of(dialogContext).pop();
                                    } catch (_) {
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          isSubmitting = false;
                                        });
                                      }
                                    }
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
      },
    );
  }

  Future<void> _showCountryPicker() async {
    final selectedCountry = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.68,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2DCE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'اختار بلد',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _countryOptions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = _countryOptions[index];
                        final isSelected =
                            option.label == _displayCountryLabel(_country);
                        return ListTile(
                          key: ValueKey(
                            'profile-country-option-${option.label}',
                          ),
                          leading: Text(
                            option.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            option.label,
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: _primaryBlue,
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).pop(option.label);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedCountry == null || selectedCountry == _country) {
      return;
    }

    final previousCountry = _country;
    setState(() {
      _country = selectedCountry;
    });

    try {
      await _persistProfile();
    } catch (_) {
      if (mounted) {
        setState(() {
          _country = previousCountry;
        });
      }
    }
  }

  Future<void> _showBirthDatePicker() async {
    final initialParts = _birthDatePartsFromValue(_birthDate);
    var selectedDay = initialParts.day;
    var selectedMonth = initialParts.month;
    var selectedYear = initialParts.year;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x295D5D5D),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final maxDay = _daysInMonth(selectedYear, selectedMonth);
            if (selectedDay > maxDay) {
              selectedDay = maxDay;
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Container(
                  width: 327,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _NumberPickerField(
                                fieldKey: const ValueKey(
                                  'profile-birthdate-day-picker',
                                ),
                                label: 'اليوم',
                                value: selectedDay,
                                values: List<int>.generate(
                                  maxDay,
                                  (i) => i + 1,
                                ),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setDialogState(() {
                                    selectedDay = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _NumberPickerField(
                                fieldKey: const ValueKey(
                                  'profile-birthdate-month-picker',
                                ),
                                label: 'الشهر',
                                value: selectedMonth,
                                values: List<int>.generate(12, (i) => i + 1),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setDialogState(() {
                                    selectedMonth = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _NumberPickerField(
                                fieldKey: const ValueKey(
                                  'profile-birthdate-year-picker',
                                ),
                                label: 'السنة',
                                value: selectedYear,
                                values: _birthDateYears(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setDialogState(() {
                                    selectedYear = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton(
                            key: const ValueKey(
                              'profile-birthdate-dialog-confirm',
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isSubmitting = true;
                                    });
                                    final previousBirthDate = _birthDate;
                                    _birthDate = _formatIsoBirthDate(
                                      selectedYear.toString(),
                                      selectedMonth.toString(),
                                      selectedDay.toString(),
                                    );
                                    try {
                                      await _persistProfile();
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    } catch (_) {
                                      _birthDate = previousBirthDate;
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          isSubmitting = false;
                                        });
                                      }
                                    }
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
            );
          },
        );
      },
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    if (_isPickingAvatar) {
      return;
    }

    _isPickingAvatar = true;
    XFile? pickedFile;
    try {
      final picker = ImagePicker();
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
    } finally {
      _isPickingAvatar = false;
    }

    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();
    final previous = _avatarAsset;
    final draft = ProfileAvatarDraft(
      fileName: pickedFile.name,
      mimeType: _mimeTypeForFileName(pickedFile.name),
      bytes: bytes,
    );

    setState(() {
      _avatarAsset = previous;
    });

    try {
      await _persistProfile(avatarDraft: draft);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث صورة الحساب')));
    } catch (_) {}
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

  String _displayBirthDate(String value) {
    final normalized = _normalizeBirthDateForApi(value);
    final parts = normalized.split('-');
    if (parts.length != 3) {
      return value;
    }
    return '${parts[0]}/${parts[1]}/${parts[2]}';
  }

  String _displayCountryLabel(String value) {
    final normalized = value.trim();
    return switch (normalized.toLowerCase()) {
      'egypt' => 'مصر',
      'saudi arabia' => 'السعودية',
      'united arab emirates' => 'الإمارات',
      'uae' => 'الإمارات',
      'kuwait' => 'الكويت',
      'qatar' => 'قطر',
      'bahrain' => 'البحرين',
      'oman' => 'عمان',
      'jordan' => 'الأردن',
      'palestine' => 'فلسطين',
      'lebanon' => 'لبنان',
      'iraq' => 'العراق',
      'morocco' => 'المغرب',
      'algeria' => 'الجزائر',
      'tunisia' => 'تونس',
      'libya' => 'ليبيا',
      'sudan' => 'السودان',
      'turkey' => 'تركيا',
      'united states' => 'الولايات المتحدة',
      'usa' => 'الولايات المتحدة',
      'united kingdom' => 'المملكة المتحدة',
      'uk' => 'المملكة المتحدة',
      _ => normalized,
    };
  }

  String _normalizeBirthDateForApi(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final isoMatch = RegExp(
      r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$',
    ).firstMatch(trimmed);
    if (isoMatch != null) {
      return _formatIsoBirthDate(
        isoMatch.group(1)!,
        isoMatch.group(2)!,
        isoMatch.group(3)!,
      );
    }

    final dayFirstMatch = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(trimmed);
    if (dayFirstMatch != null) {
      return _formatIsoBirthDate(
        dayFirstMatch.group(3)!,
        dayFirstMatch.group(2)!,
        dayFirstMatch.group(1)!,
      );
    }

    return trimmed;
  }

  String _formatIsoBirthDate(String year, String month, String day) {
    return '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
  }

  _BirthDateParts _birthDatePartsFromValue(String value) {
    final now = DateTime.now();
    final normalized = _normalizeBirthDateForApi(value);
    final parts = normalized.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        final minYear = _birthDateYears().last;
        final maxYear = _birthDateYears().first;
        final safeYear = year.clamp(minYear, maxYear);
        final safeMonth = month.clamp(1, 12);
        final safeDay = day.clamp(1, _daysInMonth(safeYear, safeMonth));
        return _BirthDateParts(day: safeDay, month: safeMonth, year: safeYear);
      }
    }

    return _BirthDateParts(day: 1, month: 1, year: now.year - 18);
  }

  List<int> _birthDateYears() {
    final currentYear = DateTime.now().year;
    return List<int>.generate(
      currentYear - 1949,
      (index) => currentYear - index,
    );
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> _handleFieldTap(_EditableFieldData field) async {
    switch (field.label) {
      case 'الاسم':
        return _showEditDialog(
          title: 'الاسم',
          initialValue: _displayName,
          inputKey: 'profile-name-dialog-input',
          confirmKey: 'profile-name-dialog-confirm',
          textDirection: TextDirection.rtl,
          onConfirm: (value) {
            if (value.isNotEmpty) {
              _displayName = value;
            }
          },
        );
      case 'عيد ميلاد':
        return _showBirthDatePicker();
      case 'الدولة الخاصة بك':
        return _showCountryPicker();
      case 'توقيع شخصي':
        return _showEditDialog(
          title: 'توقيع شخصي',
          initialValue: _signatureText,
          inputKey: 'profile-signature-dialog-input',
          confirmKey: 'profile-signature-dialog-confirm',
          textDirection: TextDirection.rtl,
          onConfirm: (value) {
            _signatureText = value;
          },
        );
      default:
        return;
    }
  }

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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
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
                                      onTap: () => Navigator.of(context).pop(),
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
                              _ProfileAvatarGrid(
                                avatarPath: _avatarAsset,
                                appearance: _appearance,
                                onPickImage: _pickAvatarFromGallery,
                              ),
                              if (_isSaving) ...[
                                const SizedBox(height: 18),
                                const LinearProgressIndicator(
                                  color: _primaryBlue,
                                ),
                              ],
                              const SizedBox(height: 30),
                              ..._fields.map(
                                (field) => _EditableFieldRow(
                                  data: field,
                                  onTap: field.showEditButton
                                      ? () => _handleFieldTap(field)
                                      : null,
                                ),
                              ),
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
}

class _ProfileAvatarGrid extends StatelessWidget {
  const _ProfileAvatarGrid({
    required this.avatarPath,
    required this.appearance,
    required this.onPickImage,
  });

  final String avatarPath;
  final ProfileAppearanceData appearance;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final uploadSlots = _ProfileEditScreenState._photoTiles
        .skip(1)
        .take(5)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = ((constraints.maxWidth - 30) / 3).clamp(92.0, 100.0);
        return Wrap(
          textDirection: TextDirection.rtl,
          spacing: 15,
          runSpacing: 15,
          children: [
            _AvatarTile(
              size: tileSize,
              label: null,
              imagePath: avatarPath,
              appearance: appearance,
              onTap: onPickImage,
            ),
            ...uploadSlots.map(
              (slot) => _AvatarTile(
                size: tileSize,
                label: slot.levelLabel,
                imagePath: null,
                appearance: const ProfileAppearanceData(),
                onTap: onPickImage,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.size,
    required this.label,
    required this.imagePath,
    required this.appearance,
    required this.onTap,
  });

  final double size;
  final String? label;
  final String? imagePath;
  final ProfileAppearanceData appearance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = this.imagePath;
    return Semantics(
      label: imagePath == null
          ? 'profile-avatar-upload'
          : 'profile-avatar-current',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _ProfileEditScreenState._photoPlaceholder,
                borderRadius: BorderRadius.circular(5),
              ),
              clipBehavior: Clip.antiAlias,
              child: imagePath == null
                  ? const Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: _ProfileEditScreenState._primaryBlue,
                          fontSize: 35,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    )
                  : Center(
                      child: ProfileDecoratedAvatar(
                        avatarAsset: imagePath,
                        appearance: appearance,
                        size: size * 0.76,
                      ),
                    ),
            ),
            if (label != null)
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
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

class _NumberPickerField extends StatelessWidget {
  const _NumberPickerField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ProfileEditScreenState._primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _ProfileEditScreenState._primaryBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: fieldKey,
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              iconEnabledColor: Colors.white,
              selectedItemBuilder: (context) {
                return values.map((item) {
                  return Center(
                    child: Text(
                      item.toString().padLeft(2, '0'),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList();
              },
              items: values.map((item) {
                return DropdownMenuItem<int>(
                  value: item,
                  child: Center(
                    child: Text(
                      item.toString().padLeft(2, '0'),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: _ProfileEditScreenState._primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryOption {
  const _CountryOption({required this.label, required this.flag});

  final String label;
  final String flag;
}

class _BirthDateParts {
  const _BirthDateParts({
    required this.day,
    required this.month,
    required this.year,
  });

  final int day;
  final int month;
  final int year;
}

class _PhotoTileData {
  const _PhotoTileData({required this.imageAsset, this.levelLabel});

  final String imageAsset;
  final String? levelLabel;
}

class _EditableFieldData {
  const _EditableFieldData({
    required this.label,
    required this.value,
    this.showEditButton = false,
  });

  final String label;
  final String value;
  final bool showEditButton;
}
