import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import '../../data/profile_account_repository.dart';

enum ProfileDetailSection { level, vip, svip, tasks, badges, guide }

class ProfileDetailInfoScreen extends StatefulWidget {
  const ProfileDetailInfoScreen({super.key, required this.section});

  final ProfileDetailSection section;

  @override
  State<ProfileDetailInfoScreen> createState() =>
      _ProfileDetailInfoScreenState();
}

class _ProfileDetailInfoScreenState extends State<ProfileDetailInfoScreen> {
  ProfileSummaryData? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.section == ProfileDetailSection.guide) {
      _isLoading = false;
      return;
    }
    _load();
  }

  Future<void> _load() async {
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
                color: const Color(0xFFF6F6F6),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        color: const Color(0xFF285F98),
                        onRefresh: widget.section == ProfileDetailSection.guide
                            ? () async {}
                            : _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(17, 46, 17, 24),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _DetailTopBar(
                                  title: _titleForSection(widget.section),
                                  onBack: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(height: 26),
                                ..._buildCards(),
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

  List<Widget> _buildCards() {
    if (widget.section == ProfileDetailSection.guide) {
      return const [
        _InfoCard(
          title: 'كيفية استخدام التطبيق',
          lines: [
            '1. أكمل بيانات حسابك من شاشة التحرير حتى تظهر بشكل صحيح داخل التطبيق.',
            '2. استخدم المتجر والحقيبة والمحفظة من البروفايل لإدارة كل ما يخص حسابك.',
            '3. فعّل إعدادات الخصوصية والإشعارات من شاشة الإعدادات حسب أسلوب استخدامك.',
            '4. عند وجود أي مشكلة استخدم مركز الدعم الفني وارفق صورًا توضح المشكلة.',
          ],
        ),
      ];
    }

    final summary = _summary;
    if (summary == null) {
      return const [
        _InfoCard(
          title: 'تعذر التحميل',
          lines: ['تعذر تحميل بيانات هذا القسم.'],
        ),
      ];
    }

    switch (widget.section) {
      case ProfileDetailSection.level:
        return [
          _InfoCard(
            title: 'المستوى الحالي',
            lines: [
              'المستوى: Lv.${summary.status.levelCurrent}',
              'المستوى التالي: Lv.${summary.status.levelNext}',
              'نسبة التقدم: ${summary.status.levelProgressPercent}%',
            ],
          ),
        ];
      case ProfileDetailSection.vip:
        return [
          _InfoCard(
            title: 'حالة VIP',
            lines: [
              'الدرجة الحالية: ${summary.status.vipTier}',
              'يتم التحكم فيها من لوحة الأدمن وفق حالة المستخدم.',
            ],
          ),
        ];
      case ProfileDetailSection.svip:
        return [
          _InfoCard(
            title: 'حالة SVIP',
            lines: [
              'الدرجة الحالية: ${summary.status.svipTier}',
              'يتم التحكم فيها من لوحة الأدمن وفق حالة المستخدم.',
            ],
          ),
        ];
      case ProfileDetailSection.tasks:
        final progress = summary.status.tasksTotal == 0
            ? 0.0
            : summary.status.tasksCompleted / summary.status.tasksTotal;
        return [
          _InfoCard(
            title: 'المهام',
            lines: [
              'المهام المكتملة: ${summary.status.tasksCompleted}',
              'إجمالي المهام: ${summary.status.tasksTotal}',
            ],
            progress: progress,
          ),
        ];
      case ProfileDetailSection.badges:
        return [
          _InfoCard(
            title: 'الشارات والحالة',
            lines: [
              'عدد الشارات: ${summary.status.badgesCount}',
              'البريد موثق: ${summary.user.emailVerified ? 'نعم' : 'لا'}',
              'الهاتف موثق: ${summary.user.phoneVerified ? 'نعم' : 'لا'}',
              'نوع الحساب: ${summary.user.authProvider}',
              'الوكالة: ${summary.user.agencyRole ?? 'لا يوجد'}',
            ],
          ),
        ];
      case ProfileDetailSection.guide:
        return const [];
    }
  }

  String _titleForSection(ProfileDetailSection section) {
    switch (section) {
      case ProfileDetailSection.level:
        return 'المستوى';
      case ProfileDetailSection.vip:
        return 'VIP';
      case ProfileDetailSection.svip:
        return 'SVIP';
      case ProfileDetailSection.tasks:
        return 'المهام';
      case ProfileDetailSection.badges:
        return 'الشارات';
      case ProfileDetailSection.guide:
        return 'كيفية استخدام التطبيق';
    }
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.title, required this.onBack});

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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines, this.progress});

  final String title;
  final List<String> lines;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          for (final line in lines) ...[
            Text(
              line,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF285F98),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 10,
                backgroundColor: const Color(0xFFE4ECF6),
                color: const Color(0xFF285F98),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
