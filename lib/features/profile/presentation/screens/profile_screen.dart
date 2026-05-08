import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/data/auth_flow_store.dart';
import '../../../auth/data/google_auth_service.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/profile_account_repository.dart';
import '../../data/profile_agency_repository.dart';
import 'profile_connections_screen.dart';
import '../widgets/profile_decorated_avatar.dart';

final class ProfileScreenArgs {
  const ProfileScreenArgs({
    this.userId,
    this.fallbackName,
    this.fallbackAvatarAsset,
    this.fallbackHandle,
    this.isCurrentUser = false,
  });

  const ProfileScreenArgs.currentUser()
    : userId = null,
      fallbackName = null,
      fallbackAvatarAsset = null,
      fallbackHandle = null,
      isCurrentUser = true;

  final int? userId;
  final String? fallbackName;
  final String? fallbackAvatarAsset;
  final String? fallbackHandle;
  final bool isCurrentUser;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.args = const ProfileScreenArgs.currentUser(),
  });

  final ProfileScreenArgs args;

  static const Color primaryBlue = Color(0xFF285F98);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _surfaceGrey = Color(0xFFEDEDED);

  ProfileSummaryData? _summary;
  bool _isLoading = true;

  bool get _isCurrentUser => widget.args.isCurrentUser;
  bool _isOpeningChat = false;

  static const List<_ProfileActionItemData> _walletItems = [
    _ProfileActionItemData(
      label: 'الحقيبة',
      assetPath: 'assets/images/profile_bag_icon.png',
      backgroundColor: Color(0xFF96CAB2),
      routeName: AppRoutes.profileBag,
    ),
    _ProfileActionItemData(
      label: 'المتجر',
      assetPath: 'assets/images/profile_store_icon.png',
      backgroundColor: Color(0xFF96DFD8),
      routeName: AppRoutes.profileStore,
    ),
    _ProfileActionItemData(
      label: 'الشحن',
      assetPath: 'assets/images/profile_charge_icon.png',
      backgroundColor: Color(0xFFE6C1B3),
      routeName: AppRoutes.profileWallet,
    ),
    _ProfileActionItemData(
      label: 'الدخل',
      assetPath: 'assets/images/profile_income_icon.png',
      backgroundColor: Color(0xFFE6D3B1),
      routeName: AppRoutes.profileIncome,
    ),
  ];

  static const List<_ProfileActionItemData> _statusItems = [
    _ProfileActionItemData(
      label: 'المستوى',
      assetPath: 'assets/images/profile_level_icon.png',
      backgroundColor: Color(0xFFCCFAC0),
      routeName: AppRoutes.profileLevel,
    ),
    _ProfileActionItemData(
      label: 'SVIP',
      assetPath: 'assets/images/profile_svip_icon.png',
      backgroundColor: Color(0xFFCBF5F9),
      routeName: AppRoutes.profileSvip,
    ),
    _ProfileActionItemData(
      label: 'VIP',
      assetPath: 'assets/images/profile_vip_icon.png',
      backgroundColor: Color(0xFFEECBB7),
      routeName: AppRoutes.profileVip,
    ),
    _ProfileActionItemData(
      label: 'المهام',
      assetPath: 'assets/images/profile_tasks_icon.png',
      backgroundColor: Color(0xFF98D0FA),
      routeName: AppRoutes.profileTasks,
    ),
  ];

  static const List<_ProfileActionItemData> _agencyItems = [
    _ProfileActionItemData(
      label: 'كود الدعوة',
      assetPath: 'assets/images/profile_invitation_icon.png',
      backgroundColor: Color(0xFFE8C6AE),
      routeName: AppRoutes.profileInvitationCode,
    ),
    _ProfileActionItemData(
      label: 'انضم إلى وكالة',
      assetPath: 'assets/images/profile_join_agency_icon.png',
      backgroundColor: Color(0xFFB5EAFB),
      routeName: AppRoutes.profileJoinAgency,
    ),
    _ProfileActionItemData(
      label: 'فتح وكالة',
      assetPath: 'assets/images/profile_open_agency_icon.png',
      backgroundColor: Color(0xFFEDCDCA),
      routeName: AppRoutes.profileOpenAgency,
    ),
  ];

  static const List<_ProfileMenuActionData> _menuItems = [
    _ProfileMenuActionData(
      label: 'مركز الدعم',
      assetPath: 'assets/images/profile_support_icon.png',
      routeName: AppRoutes.profileSupportCenter,
    ),
    _ProfileMenuActionData(
      label: 'الشارات',
      assetPath: 'assets/images/profile_badges_icon.png',
      routeName: AppRoutes.profileBadges,
    ),
    _ProfileMenuActionData(
      label: 'كيفية استخدام التطبيق',
      assetPath: 'assets/images/profile_app_usage_icon.png',
      routeName: AppRoutes.profileGuide,
    ),
    _ProfileMenuActionData(
      label: 'الإعدادات',
      assetPath: 'assets/images/profile_settings_icon.png',
      routeName: AppRoutes.profileSettings,
    ),
    _ProfileMenuActionData(
      label: 'تسجيل الخروج',
      assetPath: 'assets/images/profile_logout_icon.png',
      isLogout: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = _isCurrentUser
          ? await ProfileAccountRepository.instance.loadSummary()
          : await _loadVisitorSummary();
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

  Future<ProfileSummaryData> _loadVisitorSummary() async {
    final userId = widget.args.userId;
    if (userId != null && userId > 0) {
      return ProfileAccountRepository.instance.loadUserSummary(userId: userId);
    }

    return _fallbackVisitorSummary();
  }

  ProfileSummaryData _fallbackVisitorSummary() {
    final name = widget.args.fallbackName?.trim();
    final avatar = widget.args.fallbackAvatarAsset?.trim();
    final handle = widget.args.fallbackHandle?.trim();

    return ProfileSummaryData(
      user: ProfileUserData(
        id: 0,
        email: null,
        phone: null,
        nickname: name == null || name.isEmpty ? 'Hallo Party User' : name,
        birthdate: null,
        gender: null,
        country: 'Egypt',
        status: 'active',
        authProvider: 'password',
        emailVerified: false,
        phoneVerified: false,
        profileHandle: handle == null || handle.isEmpty ? 'زائر' : handle,
        signatureText: 'ليس لديك المقدمة الشخصية',
        avatarAsset: avatar == null || avatar.isEmpty
            ? 'assets/images/post_author_avatar.png'
            : avatar,
        agencyId: null,
        agencyRole: null,
      ),
      stats: const ProfileStatsData(
        followingCount: 0,
        followersCount: 0,
        friendsCount: 0,
      ),
      status: const ProfileStatusData(
        levelCurrent: 0,
        levelNext: 1,
        levelProgressPercent: 0,
        vipTier: 'VIP 0',
        svipTier: 'SVIP 0',
        badgesCount: 0,
        tasksCompleted: 0,
        tasksTotal: 1,
      ),
      settings: const ProfileSettingsData(
        privateProfile: false,
        allowDirectMessages: true,
        showOnlineStatus: true,
        receiveChatNotifications: true,
        receiveLiveNotifications: true,
        receiveRoomInvites: true,
        receivePartyInvites: true,
        preferredLanguage: 'ar',
      ),
    );
  }

  Future<void> _openRoute(String routeName, {Object? arguments}) async {
    await Navigator.of(context).pushNamed(routeName, arguments: arguments);
    if (!mounted) {
      return;
    }
    await _loadSummary();
  }

  Future<void> _openDirectChat(ProfileUserData user) async {
    if (_isOpeningChat || user.id < 1) {
      return;
    }

    setState(() {
      _isOpeningChat = true;
    });

    try {
      final conversation = await ChatRepository.instance.openDirectThread(
        userId: user.id,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushNamed(
        AppRoutes.chatConversation,
        arguments: conversation.thread.id,
      );
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
          _isOpeningChat = false;
        });
      }
    }
  }

  Future<void> _showAgencyCodeDialog() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final summary = await ProfileAgencyRepository.instance.loadSummary();
      if (!mounted) {
        return;
      }

      String title = 'كود الدعوة';
      String body = 'لا يوجد كود وكالة متاح الآن.';
      String? code;

      if (summary.agency != null) {
        title = summary.agency!.name;
        code = summary.agency!.invitationCode;
        body = 'كود الدعوة الخاص بوكالتك جاهز للنسخ.';
      } else if (summary.pendingOpenRequest != null) {
        title = 'طلب فتح وكالة';
        body =
            'طلبك ما زال قيد المراجعة برقم ${summary.pendingOpenRequest!.requestCode}.';
      } else if (summary.pendingJoinRequest != null) {
        title = 'طلب الانضمام للوكالة';
        body =
            'طلب الانضمام ما زال قيد المراجعة برقم ${summary.pendingJoinRequest!.requestCode}.';
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                title,
                style: const TextStyle(
                  color: ProfileScreen.primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    body,
                    style: const TextStyle(
                      color: ProfileScreen.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (code != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      code,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (code != null)
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code!));
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود الدعوة')),
                      );
                    },
                    child: const Text('نسخ'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _showLogoutConfirmationDialog() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'profile-logout-dialog',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: Container(color: const Color(0x4DB3A1A1)),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  key: const ValueKey('profile-logout-dialog'),
                  width: 306,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'هل انت متاكد انك تريد تسجيل الخروج',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ProfileScreen.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 20 / 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 28,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              key: const ValueKey('profile-logout-confirm'),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                final authProvider = AuthFlowStore
                                    .instance
                                    .currentUser?['auth_provider']
                                    ?.toString();
                                if (authProvider == 'google') {
                                  await GoogleAuthService.instance.signOut();
                                }
                                await AuthFlowStore.instance.clearSession();
                                if (!mounted) {
                                  return;
                                }
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.authEntry,
                                  (route) => false,
                                );
                              },
                              child: const Text('تسجيل الخروج'),
                            ),
                            TextButton(
                              key: const ValueKey('profile-logout-cancel'),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('الغاء'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
                color: _surfaceGrey,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _summary == null
                    ? const Center(child: Text('تعذر تحميل الملف الشخصي'))
                    : RefreshIndicator(
                        color: ProfileScreen.primaryBlue,
                        onRefresh: _loadSummary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _ProfileHeader(
                                summary: _summary!,
                                isCurrentUser: _isCurrentUser,
                                onTopActionTap: _isCurrentUser
                                    ? _showAgencyCodeDialog
                                    : () => Navigator.of(context).pop(),
                                onProfileTap: _isCurrentUser
                                    ? () => _openRoute(AppRoutes.profileEdit)
                                    : () {},
                                onStatTap: (tab) => _openRoute(
                                  AppRoutes.profileConnections,
                                  arguments: ProfileConnectionsScreenArgs(
                                    initialTab: tab,
                                    isCurrentUser: _isCurrentUser,
                                    userId: _summary!.user.id > 0
                                        ? _summary!.user.id
                                        : widget.args.userId,
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -58),
                                child: Column(
                                  children: [
                                    if (_isCurrentUser) ...[
                                      _ProfileActionCard(
                                        items: _walletItems,
                                        onItemTap: (item) =>
                                            _openRoute(item.routeName!),
                                      ),
                                      const SizedBox(height: 10),
                                      _ProfileActionCard(
                                        items: _statusItems,
                                        onItemTap: (item) =>
                                            _openRoute(item.routeName!),
                                      ),
                                      const SizedBox(height: 10),
                                      _ProfileActionCard(
                                        items: _agencyItems,
                                        onItemTap: (item) =>
                                            _openRoute(item.routeName!),
                                      ),
                                      const SizedBox(height: 20),
                                      _ProfileMenuSection(
                                        items: _menuItems,
                                        onTap: (item) {
                                          if (item.isLogout) {
                                            _showLogoutConfirmationDialog();
                                            return;
                                          }
                                          _openRoute(item.routeName!);
                                        },
                                      ),
                                    ] else ...[
                                      _VisitorProfileSection(
                                        summary: _summary!,
                                        isOpeningChat: _isOpeningChat,
                                        onMessageTap: () =>
                                            _openDirectChat(_summary!.user),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            if (_isCurrentUser)
              const MainBottomNavigation(
                currentTab: MainBottomNavigationTab.profile,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.summary,
    required this.isCurrentUser,
    required this.onTopActionTap,
    required this.onProfileTap,
    required this.onStatTap,
  });

  final ProfileSummaryData summary;
  final bool isCurrentUser;
  final VoidCallback onTopActionTap;
  final VoidCallback onProfileTap;
  final ValueChanged<ProfileConnectionsTab> onStatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ProfileScreen.primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 82),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onTopActionTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF9DB2CE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isCurrentUser
                    ? Image.asset(
                        'assets/images/profile_top_icon.png',
                        width: 24,
                        height: 24,
                        filterQuality: FilterQuality.high,
                      )
                    : const Icon(
                        Icons.arrow_back_rounded,
                        color: ProfileScreen.primaryBlue,
                        size: 24,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'profile-edit-entry',
            button: isCurrentUser,
            child: InkWell(
              key: const ValueKey('profile-edit-entry'),
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    ProfileDecoratedAvatar(
                      avatarAsset: summary.user.avatarAsset,
                      appearance: summary.appearance,
                      size: 80,
                      showOnlineBadge: true,
                      onlineBadgeBorderColor: ProfileScreen.primaryBlue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary.user.nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.user.profileHandle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/profile_country_flag.png',
                          width: 15,
                          height: 15,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ID:${summary.user.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (summary.user.agencyId != null) ...[
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/profile_agency_flag.png',
                            width: 20,
                            height: 20,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    label: 'اتابع',
                    value: summary.stats.followingCount.toString(),
                    onTap: () => onStatTap(ProfileConnectionsTab.following),
                  ),
                ),
                Expanded(
                  child: _ProfileStat(
                    label: 'المتابعون',
                    value: summary.stats.followersCount.toString(),
                    onTap: () => onStatTap(ProfileConnectionsTab.followers),
                  ),
                ),
                Expanded(
                  child: _ProfileStat(
                    label: 'الأصدقاء',
                    value: summary.stats.friendsCount.toString(),
                    onTap: () => onStatTap(ProfileConnectionsTab.friends),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          _ProfileLevelBar(
            currentLevel: summary.status.levelCurrent,
            nextLevel: summary.status.levelNext,
            progressPercent: summary.status.levelProgressPercent,
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLevelBar extends StatelessWidget {
  const _ProfileLevelBar({
    required this.currentLevel,
    required this.nextLevel,
    required this.progressPercent,
  });

  final int currentLevel;
  final int nextLevel;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final progress = (progressPercent / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 303,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5590CD),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: -11,
            child: _LevelChip(label: 'Lv.$currentLevel'),
          ),
          Positioned(
            right: 0,
            bottom: -11,
            child: _LevelChip(label: 'Lv.$nextLevel'),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 15,
      decoration: BoxDecoration(
        color: const Color(0xFF9DB2CE),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _VisitorProfileSection extends StatelessWidget {
  const _VisitorProfileSection({
    required this.summary,
    required this.isOpeningChat,
    required this.onMessageTap,
  });

  final ProfileSummaryData summary;
  final bool isOpeningChat;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'نبذة عن الحساب',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: ProfileScreen.primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                summary.user.signatureText,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF52657A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _VisitorInfoChip(label: summary.user.country),
                  _VisitorInfoChip(label: summary.status.vipTier),
                  _VisitorInfoChip(label: 'Lv.${summary.status.levelCurrent}'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isOpeningChat ? null : onMessageTap,
                icon: isOpeningChat
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_rounded, size: 18),
                label: Text(isOpeningChat ? 'جارٍ فتح المحادثة...' : 'مراسلة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileScreen.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

class _VisitorInfoChip extends StatelessWidget {
  const _VisitorInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ProfileScreen.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.items, required this.onItemTap});

  final List<_ProfileActionItemData> items;
  final ValueChanged<_ProfileActionItemData> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: _ProfileActionItem(
                    data: item,
                    onTap: () => onItemTap(item),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  const _ProfileActionItem({required this.data, required this.onTap});

  final _ProfileActionItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: data.backgroundColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                data.assetPath,
                width: 30,
                height: 30,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ProfileScreen.primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 20 / 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection({required this.items, required this.onTap});

  final List<_ProfileMenuActionData> items;
  final ValueChanged<_ProfileMenuActionData> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => onTap(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: ProfileScreen.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Image.asset(
                            item.assetPath,
                            width: 30,
                            height: 30,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileActionItemData {
  const _ProfileActionItemData({
    required this.label,
    required this.assetPath,
    required this.backgroundColor,
    this.routeName,
  });

  final String label;
  final String assetPath;
  final Color backgroundColor;
  final String? routeName;
}

class _ProfileMenuActionData {
  const _ProfileMenuActionData({
    required this.label,
    required this.assetPath,
    this.routeName,
    this.isLogout = false,
  });

  final String label;
  final String assetPath;
  final String? routeName;
  final bool isLogout;
}
