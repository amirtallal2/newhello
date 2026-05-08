import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/profile_referral_repository.dart';
import 'profile_screen.dart';

enum _InviteTab { mine, rewards, leaderboard }

class ProfileInvitationCodeScreen extends StatefulWidget {
  const ProfileInvitationCodeScreen({super.key});

  @override
  State<ProfileInvitationCodeScreen> createState() =>
      _ProfileInvitationCodeScreenState();
}

class _ProfileInvitationCodeScreenState
    extends State<ProfileInvitationCodeScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _dark = Color(0xE0030209);

  ProfileReferralSummaryData? _summary;
  _InviteTab _selectedTab = _InviteTab.mine;
  bool _isLoading = true;

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
      final summary = await ProfileReferralRepository.instance.loadSummary();
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

  Future<void> _copyInviteCode() async {
    final summary = _summary;
    if (summary == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: summary.user.inviteCode));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ كود الدعوة')));
  }

  Future<void> _copyInviteLink([String? channel]) async {
    final summary = _summary;
    if (summary == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: summary.user.inviteLink));
    if (!mounted) {
      return;
    }
    final suffix = channel == null ? '' : ' لمشاركته عبر $channel';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم نسخ رابط الدعوة$suffix')));
  }

  void _showShareSheet() {
    final summary = _summary;
    if (summary == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 141,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'شارك رابط الدعوة',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: .85),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ShareTarget(
                          label: 'واتساب',
                          color: const Color(0xFF2BCB6E),
                          icon: Icons.chat_rounded,
                          onTap: () {
                            Navigator.of(context).pop();
                            _copyInviteLink('واتساب');
                          },
                        ),
                        _ShareTarget(
                          label: 'فيسبوك',
                          color: const Color(0xFF285F98),
                          icon: Icons.facebook_rounded,
                          onTap: () {
                            Navigator.of(context).pop();
                            _copyInviteLink('فيسبوك');
                          },
                        ),
                        _ShareTarget(
                          label: 'انسخ الرابط',
                          color: const Color(0xFF111827),
                          icon: Icons.link_rounded,
                          onTap: () {
                            Navigator.of(context).pop();
                            _copyInviteLink();
                          },
                        ),
                        _ShareTarget(
                          label: 'الكود',
                          color: const Color(0xFFE78A35),
                          icon: Icons.qr_code_rounded,
                          onTap: () {
                            Navigator.of(context).pop();
                            _copyInviteCode();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      summary.user.inviteLink,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF285F98),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  void _openProfile(int? userId, String name, String avatar, String handle) {
    if (userId == null || userId <= 0) {
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: userId,
        fallbackName: name,
        fallbackAvatarAsset: avatar,
        fallbackHandle: handle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _dark,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _summary == null
                    ? const Center(
                        child: Text(
                          'تعذر تحميل كود الدعوة',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : RefreshIndicator(
                        color: _primaryBlue,
                        onRefresh: _loadSummary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: _InviteContent(
                                summary: _summary!,
                                selectedTab: _selectedTab,
                                onCopyCode: _copyInviteCode,
                                onShare: _showShareSheet,
                                onSelectTab: (tab) {
                                  setState(() {
                                    _selectedTab = tab;
                                  });
                                },
                                onOpenProfile: _openProfile,
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
      ),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent({
    required this.summary,
    required this.selectedTab,
    required this.onCopyCode,
    required this.onShare,
    required this.onSelectTab,
    required this.onOpenProfile,
  });

  final ProfileReferralSummaryData summary;
  final _InviteTab selectedTab;
  final VoidCallback onCopyCode;
  final VoidCallback onShare;
  final ValueChanged<_InviteTab> onSelectTab;
  final void Function(int? userId, String name, String avatar, String handle)
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final stats = summary.stats;
    final rewardCards = summary.rewardCards.isEmpty
        ? [
            ProfileReferralRewardCardData(
              title: 'مكافأة التعبئة',
              percent: summary.settings.directRechargePercent,
              description: 'أرباح مباشرة من شحن الأصدقاء.',
            ),
            ProfileReferralRewardCardData(
              title: 'مكافأة الشبكة',
              percent: summary.settings.indirectRechargePercent,
              description: 'أرباح إضافية من شحن أصدقاء أصدقائك.',
            ),
          ]
        : summary.rewardCards;

    return Stack(
      children: [
        Positioned(
          top: -5,
          right: -28,
          child: _GlowCircle(
            size: 166,
            color: const Color(0xFF285F98).withValues(alpha: .88),
          ),
        ),
        Positioned(
          top: 195,
          left: -34,
          child: _GlowCircle(
            size: 200,
            color: const Color(0xFF9F9C93).withValues(alpha: .5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 58, 24, 28),
          child: Column(
            children: [
              _InviteHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: ResolvedImage(
                  path: summary.assets.headerAsset,
                  width: double.infinity,
                  height: 134,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              _InviteCodeBar(code: summary.user.inviteCode, onCopy: onCopyCode),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'يمكنك كسب المال عن طريق دعوة الاصدقاء للتسجيل في Halo Party !\nاربح اكثر من ',
                    ),
                    TextSpan(
                      text: _money(stats.dailyTargetUsd, withSymbol: false),
                      style: const TextStyle(color: Color(0xFF285F98)),
                    ),
                    const TextSpan(text: ' دولار يوميا!'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _WithdrawCard(summary: summary),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _RewardRateCard(card: rewardCards[0])),
                  const SizedBox(width: 46),
                  Expanded(
                    child: _RewardRateCard(
                      card: rewardCards.length > 1
                          ? rewardCards[1]
                          : rewardCards[0],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _InfoBanner(),
              const SizedBox(height: 15),
              _TabbedPanel(
                summary: summary,
                selectedTab: selectedTab,
                onSelectTab: onSelectTab,
                onOpenProfile: onOpenProfile,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 61,
                child: FilledButton(
                  onPressed: onShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF285F98),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'دعوة الاصدقاء',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InviteHeader extends StatelessWidget {
  const _InviteHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Halo Party',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeBar extends StatelessWidget {
  const _InviteCodeBar({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 8, 0),
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code.isEmpty ? 'يمكنك الان نسخ رمز دعوتك' : code,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            height: 24,
            child: FilledButton(
              onPressed: onCopy,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF285F98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                'نسخ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawCard extends StatelessWidget {
  const _WithdrawCard({required this.summary});

  final ProfileReferralSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final stats = summary.stats;
    return Container(
      height: 236,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ResolvedImage(
              path: summary.assets.rewardCardAsset,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .05),
                    Colors.black.withValues(alpha: .35),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_money(stats.firstWithdrawUsd, withSymbol: false)}\$',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'قم بدعوة الاصدقاء للتسجيل وسيصل مبلغ السحب إلى ${_money(stats.firstWithdrawUsd)} لأول مرة خلال ${stats.firstWithdrawDays} يوم، يمكنك الحصول على ${_money(stats.availableRewardUsd)} من المكافآت',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
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

class _RewardRateCard extends StatelessWidget {
  const _RewardRateCard({required this.card});

  final ProfileReferralRewardCardData card;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Container(
              width: 70,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF285F98), Color(0xFF0D1F32)],
                ),
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: Radius.circular(10),
                ),
              ),
              child: Text(
                card.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_trimPercent(card.percent)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    card.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
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

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'الأصدقاء الآخرون الذين تمت دعوتهم من قبل الأصدقاء لإعادة الشحن يمكنك أيضا الحصول على مكافآت بنسب مختلفة',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TabbedPanel extends StatelessWidget {
  const _TabbedPanel({
    required this.summary,
    required this.selectedTab,
    required this.onSelectTab,
    required this.onOpenProfile,
  });

  final ProfileReferralSummaryData summary;
  final _InviteTab selectedTab;
  final ValueChanged<_InviteTab> onSelectTab;
  final void Function(int? userId, String name, String avatar, String handle)
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: 'دعوتي',
                  isSelected: selectedTab == _InviteTab.mine,
                  onTap: () => onSelectTab(_InviteTab.mine),
                ),
                _TabButton(
                  label: 'مكافأة دعوة',
                  isSelected: selectedTab == _InviteTab.rewards,
                  onTap: () => onSelectTab(_InviteTab.rewards),
                ),
                _TabButton(
                  label: 'لوحة الصدارة',
                  isSelected: selectedTab == _InviteTab.leaderboard,
                  onTap: () => onSelectTab(_InviteTab.leaderboard),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (selectedTab) {
              _InviteTab.mine => _MyInvitesTab(
                key: const ValueKey('invite-tab-mine'),
                summary: summary,
                onOpenProfile: onOpenProfile,
              ),
              _InviteTab.rewards => _RewardsTab(
                key: const ValueKey('invite-tab-rewards'),
                summary: summary,
              ),
              _InviteTab.leaderboard => _LeaderboardTab(
                key: const ValueKey('invite-tab-leaderboard'),
                summary: summary,
                onOpenProfile: onOpenProfile,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF285F98) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyInvitesTab extends StatelessWidget {
  const _MyInvitesTab({
    super.key,
    required this.summary,
    required this.onOpenProfile,
  });

  final ProfileReferralSummaryData summary;
  final void Function(int? userId, String name, String avatar, String handle)
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final stats = summary.stats;
    return Column(
      children: [
        _StatsRow(
          items: [
            _StatsItem('ادعو اليوم', '${stats.todayInvites}'),
            _StatsItem('الدعوات المتراكمة', '${stats.totalInvites}'),
            _StatsItem('التسجيل', '${stats.registeredInvites}'),
            _StatsItem('لا أذكر', '${stats.unknownInvites}'),
          ],
        ),
        const SizedBox(height: 12),
        if (summary.myInvites.isEmpty)
          _EmptyState(
            image: summary.assets.emptyAsset,
            text: 'لم تقم بدعوة أصدقاء حتى الآن',
          )
        else
          ...summary.myInvites.map(
            (invite) => _PersonRewardTile(
              rank: null,
              name: invite.name,
              handle: invite.handle,
              avatar: invite.avatarAsset,
              amount: invite.rewardUsd,
              meta: invite.registeredAtLabel,
              onTap: () => onOpenProfile(
                invite.userId,
                invite.name,
                invite.avatarAsset,
                invite.handle,
              ),
            ),
          ),
      ],
    );
  }
}

class _RewardsTab extends StatelessWidget {
  const _RewardsTab({super.key, required this.summary});

  final ProfileReferralSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final stats = summary.stats;
    return Column(
      children: [
        _StatsRow(
          items: [
            _StatsItem('جائزة الأمس', _money(stats.yesterdayRewardUsd)),
            _StatsItem(
              'المكافآت المتراكمة',
              _money(stats.accumulatedRewardUsd),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (summary.rewardTransactions.isEmpty)
          _EmptyState(
            image: summary.assets.emptyAsset,
            text: 'لا توجد مكافآت دعوة حتى الآن',
          )
        else
          ...summary.rewardTransactions.map(
            (reward) => _RewardTransactionTile(reward: reward),
          ),
      ],
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({
    super.key,
    required this.summary,
    required this.onOpenProfile,
  });

  final ProfileReferralSummaryData summary;
  final void Function(int? userId, String name, String avatar, String handle)
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (summary.leaderboard.isEmpty) {
      return _EmptyState(
        image: summary.assets.emptyAsset,
        text: 'لوحة الصدارة ستظهر بعد أول دعوات حقيقية',
      );
    }

    return Column(
      children: summary.leaderboard
          .map(
            (entry) => _PersonRewardTile(
              rank: entry.rank,
              name: entry.name,
              handle: '${entry.invitedCount} دعوة',
              avatar: entry.avatarAsset,
              amount: entry.rewardUsd,
              meta: entry.handle,
              onTap: () => onOpenProfile(
                entry.userId,
                entry.name,
                entry.avatarAsset,
                entry.handle,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<_StatsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 47),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Text(
                      item.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _StatsItem {
  const _StatsItem(this.label, this.value);

  final String label;
  final String value;
}

class _PersonRewardTile extends StatelessWidget {
  const _PersonRewardTile({
    required this.rank,
    required this.name,
    required this.handle,
    required this.avatar,
    required this.amount,
    required this.meta,
    required this.onTap,
  });

  final int? rank;
  final String name;
  final String handle;
  final String avatar;
  final double amount;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                rank == null ? '' : rank.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipOval(
              child: ResolvedImage(
                path: avatar,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 97,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x4D000000),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'كسب المكافآت  ${_money(amount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTransactionTile extends StatelessWidget {
  const _RewardTransactionTile({required this.reward});

  final ProfileReferralRewardTransactionData reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reward.subtitle.isEmpty
                      ? reward.createdAtLabel
                      : reward.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(reward.amountUsd),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.image, required this.text});

  final String image;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          ResolvedImage(
            path: image,
            width: 68,
            height: 68,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _money(double value, {bool withSymbol = true}) {
  final rounded = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return withSymbol ? '$rounded\$' : rounded;
}

String _trimPercent(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
