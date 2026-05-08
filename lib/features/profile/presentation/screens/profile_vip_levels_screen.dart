import 'package:flutter/material.dart';

import '../../../../core/widgets/resolved_image.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/profile_levels_repository.dart';

class ProfileVipLevelsScreen extends StatefulWidget {
  const ProfileVipLevelsScreen({super.key});

  @override
  State<ProfileVipLevelsScreen> createState() => _ProfileVipLevelsScreenState();
}

class _ProfileVipLevelsScreenState extends State<ProfileVipLevelsScreen> {
  static const Color _dark = Color(0xFF030209);
  static const Color _gold = Color(0xFFFFCF21);

  VipLevelsSummaryData? _summary;
  int? _selectedTierNumber;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await ProfileLevelsRepository.instance.loadVipLevels();
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _selectedTierNumber ??= summary.defaultSelectedTierNumber;
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  VipLevelData? get _selectedLevel {
    final summary = _summary;
    if (summary == null || summary.levels.isEmpty) {
      return null;
    }
    final selected = _selectedTierNumber ?? summary.defaultSelectedTierNumber;
    for (final level in summary.levels) {
      if (level.tierNumber == selected) {
        return level;
      }
    }
    return summary.levels.last;
  }

  Future<void> _activateSelectedLevel() async {
    final level = _selectedLevel;
    if (level == null || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final summary = await ProfileLevelsRepository.instance.activateVip(
        levelId: level.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _selectedTierNumber = level.tierNumber;
      });
      _showMessage('تم تفعيل ${level.name} بنجاح');
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _openSendSheet() async {
    final level = _selectedLevel;
    if (level == null || _isBusy) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _VipSendSheet(
          level: level,
          onSend: (recipient) async {
            Navigator.of(sheetContext).pop();
            await _sendLevel(level, recipient);
          },
        );
      },
    );
  }

  Future<void> _sendLevel(
    VipLevelData level,
    VipRecipientData recipient,
  ) async {
    setState(() {
      _isBusy = true;
    });

    try {
      final summary = await ProfileLevelsRepository.instance.sendVip(
        levelId: level.id,
        recipientUserId: recipient.id,
        recipientName: recipient.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _selectedTierNumber = level.tierNumber;
      });
      _showMessage('تم إرسال ${level.name} إلى ${recipient.name}');
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final selectedLevel = _selectedLevel;

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _gold))
                  : summary == null || selectedLevel == null
                  ? const _VipEmptyState()
                  : RefreshIndicator(
                      color: _gold,
                      backgroundColor: const Color(0xFF202020),
                      onRefresh: _load,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 430,
                                ),
                                child: _VipLevelsContent(
                                  summary: summary,
                                  selectedLevel: selectedLevel,
                                  selectedTierNumber: selectedLevel.tierNumber,
                                  isBusy: _isBusy,
                                  onBack: () => Navigator.of(context).pop(),
                                  onSelectTier: (tier) {
                                    setState(() {
                                      _selectedTierNumber = tier;
                                    });
                                  },
                                  onActivate: _activateSelectedLevel,
                                  onSend: _openSendSheet,
                                ),
                              ),
                            ),
                          );
                        },
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

class _VipLevelsContent extends StatelessWidget {
  const _VipLevelsContent({
    required this.summary,
    required this.selectedLevel,
    required this.selectedTierNumber,
    required this.isBusy,
    required this.onBack,
    required this.onSelectTier,
    required this.onActivate,
    required this.onSend,
  });

  final VipLevelsSummaryData summary;
  final VipLevelData selectedLevel;
  final int selectedTierNumber;
  final bool isBusy;
  final VoidCallback onBack;
  final ValueChanged<int> onSelectTier;
  final VoidCallback onActivate;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final privileges = selectedLevel.privileges
        .where((item) => item.isUnlocked)
        .toList(growable: false);
    final activeSubscription = summary.currentSubscription;
    final isActiveSelected =
        activeSubscription?.isActive == true &&
        activeSubscription?.tierNumber == selectedLevel.tierNumber;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xE0030209))),
          Positioned(
            left: -150,
            right: -150,
            top: -180,
            height: 470,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF5F4A19).withValues(alpha: 0.95),
                    const Color(0xFF1C2133).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 48, 21, 28),
            child: Column(
              children: [
                _VipHeader(onBack: onBack),
                const SizedBox(height: 30),
                _VipTierTabs(
                  levels: summary.levels,
                  selectedTierNumber: selectedTierNumber,
                  onSelectTier: onSelectTier,
                ),
                const SizedBox(height: 36),
                ResolvedImage(
                  path: selectedLevel.heroAssetPath,
                  width: 150,
                  height: 147,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 5),
                _VipStatusPill(
                  isActive: isActiveSelected,
                  tierName: selectedLevel.name,
                  expiresAt: activeSubscription?.expiresAt,
                ),
                const SizedBox(height: 44),
                const Text(
                  'مميزات حصرية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${selectedLevel.unlockedPrivilegesCount}/${selectedLevel.privilegesTotalCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 20 / 10,
                  ),
                ),
                const SizedBox(height: 10),
                _VipPrivilegeGrid(privileges: privileges),
                const SizedBox(height: 30),
                _VipActionPanel(
                  level: selectedLevel,
                  coinAsset: summary.coinAsset,
                  coinsBalance: summary.wallet.coinsBalance,
                  isBusy: isBusy,
                  isActiveSelected: isActiveSelected,
                  onActivate: onActivate,
                  onSend: onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VipHeader extends StatelessWidget {
  const _VipHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Text(
          'VIP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.24,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF25222F),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VipTierTabs extends StatelessWidget {
  const _VipTierTabs({
    required this.levels,
    required this.selectedTierNumber,
    required this.onSelectTier,
  });

  final List<VipLevelData> levels;
  final int selectedTierNumber;
  final ValueChanged<int> onSelectTier;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (final level in levels)
          Expanded(
            child: InkWell(
              onTap: () => onSelectTier(level.tierNumber),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    level.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedTierNumber == level.tierNumber
                          ? const Color(0xFFFFCF21)
                          : Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 20 / 15,
                      letterSpacing: -0.24,
                    ),
                  ),
                  const SizedBox(height: 9),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedTierNumber == level.tierNumber
                          ? const Color(0xFFFFCF21)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _VipStatusPill extends StatelessWidget {
  const _VipStatusPill({
    required this.isActive,
    required this.tierName,
    required this.expiresAt,
  });

  final bool isActive;
  final String tierName;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final text = isActive
        ? 'تم تفعيل $tierName حتى ${_formatDate(expiresAt)}'
        : 'لم يتم تفعيل خاصية VIP بعد';

    return Container(
      constraints: const BoxConstraints(minWidth: 175),
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 20 / 12,
          letterSpacing: -0.24,
        ),
      ),
    );
  }
}

class _VipPrivilegeGrid extends StatelessWidget {
  const _VipPrivilegeGrid({required this.privileges});

  final List<VipPrivilegeData> privileges;

  @override
  Widget build(BuildContext context) {
    if (privileges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'لا توجد مميزات مفعلة لهذا المستوى.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: privileges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 105,
        crossAxisSpacing: 18,
        mainAxisSpacing: 0,
      ),
      itemBuilder: (context, index) {
        final privilege = privileges[index];
        return _VipPrivilegeTile(privilege: privilege);
      },
    );
  }
}

class _VipPrivilegeTile extends StatelessWidget {
  const _VipPrivilegeTile({required this.privilege});

  final VipPrivilegeData privilege;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ResolvedImage(
            path: privilege.iconAssetPath,
            width: 55,
            height: 55,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          privilege.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.25,
            letterSpacing: -0.24,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VipActionPanel extends StatelessWidget {
  const _VipActionPanel({
    required this.level,
    required this.coinAsset,
    required this.coinsBalance,
    required this.isBusy,
    required this.isActiveSelected,
    required this.onActivate,
    required this.onSend,
  });

  final VipLevelData level;
  final String coinAsset;
  final int coinsBalance;
  final bool isBusy;
  final bool isActiveSelected;
  final VoidCallback onActivate;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 290,
          height: 61,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFFBAA00),
                Color(0xFFFBAA00),
                Color(0xFF3F3B58),
                Color(0xFF3F3B58),
              ],
              stops: [0, 0.5, 0.5, 1],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isBusy ? null : onActivate,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      isActiveSelected ? 'تجديد' : 'تفعيل',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 61, color: const Color(0xFF212026)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    Text(
                      '${_formatCompact(level.priceCoins)} / ${level.durationDays} يوم',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 20 / 12,
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(width: 5),
                    ResolvedImage(
                      path: coinAsset,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'رصيدك: ${_formatCompact(coinsBalance)} كوين',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 96,
          height: 40,
          child: ElevatedButton(
            onPressed: isBusy ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF285F98),
              disabledBackgroundColor: const Color(
                0xFF285F98,
              ).withValues(alpha: 0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero,
            ),
            child: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'ارسال',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _VipSendSheet extends StatefulWidget {
  const _VipSendSheet({required this.level, required this.onSend});

  final VipLevelData level;
  final ValueChanged<VipRecipientData> onSend;

  @override
  State<_VipSendSheet> createState() => _VipSendSheetState();
}

class _VipSendSheetState extends State<_VipSendSheet> {
  final TextEditingController _queryController = TextEditingController();
  List<VipRecipientData> _recipients = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final recipients = await ProfileLevelsRepository.instance
          .searchVipRecipients(query: _queryController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _recipients = recipients;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF171722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'إرسال ${widget.level.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _queryController,
                onSubmitted: (_) => _loadRecipients(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المستخدم أو ID',
                  hintStyle: const TextStyle(color: Colors.white54),
                  suffixIcon: IconButton(
                    onPressed: _loadRecipients,
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF25263A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 310),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFCF21),
                          ),
                        ),
                      )
                    : _recipients.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'لا توجد نتائج مناسبة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _recipients.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: Colors.white10),
                        itemBuilder: (context, index) {
                          final recipient = _recipients[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipOval(
                              child: ResolvedImage(
                                path: recipient.avatarAsset,
                                width: 44,
                                height: 44,
                              ),
                            ),
                            title: Text(
                              recipient.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              recipient.handle,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: TextButton(
                              onPressed: () => widget.onSend(recipient),
                              child: const Text(
                                'إرسال',
                                style: TextStyle(color: Color(0xFFFFCF21)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipEmptyState extends StatelessWidget {
  const _VipEmptyState();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'تعذر تحميل مستويات VIP.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatCompact(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final remaining = text.length - index;
    buffer.write(text[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) {
    return '-';
  }
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year}';
}
