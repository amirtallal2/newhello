import 'package:flutter/material.dart';

import '../../../../core/widgets/resolved_image.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/profile_account_repository.dart';

class ProfileAccountSettingsScreen extends StatefulWidget {
  const ProfileAccountSettingsScreen({super.key});

  @override
  State<ProfileAccountSettingsScreen> createState() =>
      _ProfileAccountSettingsScreenState();
}

class _ProfileAccountSettingsScreenState
    extends State<ProfileAccountSettingsScreen> {
  ProfileSummaryData? _summary;
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _background = Color(0xFFF6F6F6);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await ProfileAccountRepository.instance.loadSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSettings(ProfileSettingsData settings) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final summary = await ProfileAccountRepository.instance.updateSettings(
        settings,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تغيير كلمة المرور'),
                content: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PasswordField(
                        controller: currentController,
                        hintText: 'كلمة المرور الحالية',
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: newController,
                        hintText: 'كلمة المرور الجديدة',
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: confirmController,
                        hintText: 'تأكيد كلمة المرور الجديدة',
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              await ProfileAccountRepository.instance
                                  .changePassword(
                                    currentPassword: currentController.text
                                        .trim(),
                                    newPassword: newController.text.trim(),
                                    confirmPassword: confirmController.text
                                        .trim(),
                                  );
                              if (!dialogContext.mounted) {
                                return;
                              }
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تحديث كلمة المرور بنجاح'),
                                ),
                              );
                            } catch (error) {
                              if (!dialogContext.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                ),
                              );
                            } finally {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  isSubmitting = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                    ),
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _summary?.settings;
    final user = _summary?.user;

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
                    : settings == null || user == null
                    ? const Center(child: Text('تعذر تحميل الإعدادات'))
                    : RefreshIndicator(
                        color: _primaryBlue,
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(17, 46, 17, 24),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProfileTopBar(
                                  title: 'الإعدادات',
                                  onBack: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(height: 28),
                                _SettingsInfoCard(user: user),
                                const SizedBox(height: 14),
                                _SettingsCard(
                                  title: 'الخصوصية والتواصل',
                                  children: [
                                    _SettingsSwitchRow(
                                      label: 'الملف الشخصي خاص',
                                      value: settings.privateProfile,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          privateProfile: value,
                                        ),
                                      ),
                                    ),
                                    _SettingsSwitchRow(
                                      label: 'السماح بالرسائل المباشرة',
                                      value: settings.allowDirectMessages,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          allowDirectMessages: value,
                                        ),
                                      ),
                                    ),
                                    _SettingsSwitchRow(
                                      label: 'إظهار حالة التواجد',
                                      value: settings.showOnlineStatus,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          showOnlineStatus: value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SettingsCard(
                                  title: 'الإشعارات والدعوات',
                                  children: [
                                    _SettingsSwitchRow(
                                      label: 'إشعارات المحادثات',
                                      value: settings.receiveChatNotifications,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          receiveChatNotifications: value,
                                        ),
                                      ),
                                    ),
                                    _SettingsSwitchRow(
                                      label: 'إشعارات اللايف',
                                      value: settings.receiveLiveNotifications,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          receiveLiveNotifications: value,
                                        ),
                                      ),
                                    ),
                                    _SettingsSwitchRow(
                                      label: 'دعوات الغرف الصوتية',
                                      value: settings.receiveRoomInvites,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          receiveRoomInvites: value,
                                        ),
                                      ),
                                    ),
                                    _SettingsSwitchRow(
                                      label: 'دعوات Party',
                                      value: settings.receivePartyInvites,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          receivePartyInvites: value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SettingsCard(
                                  title: 'إعدادات عامة',
                                  children: [
                                    _LanguageRow(
                                      value: settings.preferredLanguage,
                                      onChanged: (value) => _updateSettings(
                                        settings.copyWith(
                                          preferredLanguage: value,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _showChangePasswordDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('تغيير كلمة المرور'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isSaving) ...[
                                  const SizedBox(height: 14),
                                  const LinearProgressIndicator(
                                    color: _primaryBlue,
                                  ),
                                ],
                              ],
                            ),
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

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 38,
            height: 37,
            decoration: const BoxDecoration(
              color: Color(0xFFB4D1EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF285F98),
              size: 24,
            ),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF285F98),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 38),
      ],
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard({required this.user});

  final ProfileUserData user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: ResolvedImage(path: user.avatarAsset),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(
                    color: Color(0xFF285F98),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.profileHandle,
                  style: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? user.phone ?? 'لا توجد بيانات تواصل',
                  style: const TextStyle(
                    color: Color(0xFF285F98),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF285F98),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch.adaptive(
          value: value,
          activeTrackColor: const Color(0xFF285F98),
          onChanged: onChanged,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF285F98),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          value: value,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
        const Spacer(),
        const Text(
          'لغة التطبيق',
          style: TextStyle(
            color: Color(0xFF285F98),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
