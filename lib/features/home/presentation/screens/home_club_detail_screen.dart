import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/club_repository.dart';
import 'home_clubs_screen.dart';

class HomeClubDetailScreen extends StatefulWidget {
  const HomeClubDetailScreen({super.key, required this.clubId});

  final int clubId;

  @override
  State<HomeClubDetailScreen> createState() => _HomeClubDetailScreenState();
}

class _HomeClubDetailScreenState extends State<HomeClubDetailScreen> {
  late Future<ClubDetailData> _detailFuture;
  final TextEditingController _postController = TextEditingController();
  bool _isMembershipBusy = false;
  bool _isPosting = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<ClubDetailData> _loadDetail() {
    return ClubRepository.instance.loadClub(widget.clubId);
  }

  Future<void> _refresh() async {
    final future = _loadDetail();
    setState(() {
      _detailFuture = future;
    });
    await future;
  }

  void _goBack() {
    Navigator.of(context).pop(_changed);
  }

  Future<void> _toggleMembership(ClubData club) async {
    if (_isMembershipBusy || club.isOwner) {
      return;
    }
    setState(() {
      _isMembershipBusy = true;
    });
    try {
      if (club.isMember) {
        await ClubRepository.instance.leaveClub(club.id);
      } else {
        await ClubRepository.instance.joinClub(club.id);
      }
      _changed = true;
      await _refresh();
    } finally {
      if (mounted) {
        setState(() {
          _isMembershipBusy = false;
        });
      }
    }
  }

  Future<void> _postAnnouncement(ClubData club) async {
    final body = _postController.text.trim();
    if (_isPosting || body.isEmpty) {
      return;
    }
    setState(() {
      _isPosting = true;
    });
    try {
      final detail = await ClubRepository.instance.postAnnouncement(
        clubId: club.id,
        bodyText: body,
      );
      _postController.clear();
      _changed = true;
      if (!mounted) {
        return;
      }
      setState(() {
        _detailFuture = Future<ClubDetailData>.value(detail);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _openMember(ClubMemberData member) {
    if (member.userId == null) {
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: member.userId,
        fallbackName: member.nickname,
        fallbackAvatarAsset: member.avatarAsset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _goBack();
          }
        },
        child: Scaffold(
          backgroundColor: HomeClubsScreen.background,
          body: SafeArea(
            child: FutureBuilder<ClubDetailData>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: HomeClubsScreen.primaryBlue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _DetailError(
                    message: snapshot.error.toString(),
                    onBack: _goBack,
                    onRetry: _refresh,
                  );
                }

                final detail = snapshot.data!;
                final club = detail.club;
                return RefreshIndicator(
                  color: HomeClubsScreen.primaryBlue,
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _DetailHeader(onBack: _goBack),
                      const SizedBox(height: 18),
                      _ClubHeroCard(
                        club: club,
                        isBusy: _isMembershipBusy,
                        onToggleMembership: () => _toggleMembership(club),
                      ),
                      const SizedBox(height: 16),
                      _ClubQuickActions(club: club),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'إعلانات النادي',
                        trailing: '${detail.feed.length}',
                      ),
                      const SizedBox(height: 10),
                      if (club.isMember)
                        _PostComposer(
                          controller: _postController,
                          isPosting: _isPosting,
                          onSend: () => _postAnnouncement(club),
                        ),
                      if (club.isMember) const SizedBox(height: 12),
                      if (detail.feed.isEmpty)
                        const _EmptyBox(
                          icon: Icons.campaign_rounded,
                          title: 'لا توجد إعلانات حتى الآن',
                          subtitle: 'أول إعلان سيظهر هنا لأعضاء النادي.',
                        )
                      else
                        ...detail.feed.map(_FeedTile.new),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: 'الأعضاء',
                        trailing: '${detail.members.length}',
                      ),
                      const SizedBox(height: 10),
                      ...detail.members.map(
                        (member) => _MemberTile(
                          member: member,
                          onTap: () => _openMember(member),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          onTap: onBack,
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: HomeClubsScreen.primaryBlue,
            size: 18,
          ),
        ),
        const Spacer(),
        const Text(
          'تفاصيل النادي',
          style: TextStyle(
            color: HomeClubsScreen.primaryBlue,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 42),
      ],
    );
  }
}

class _ClubHeroCard extends StatelessWidget {
  const _ClubHeroCard({
    required this.club,
    required this.isBusy,
    required this.onToggleMembership,
  });

  final ClubData club;
  final bool isBusy;
  final VoidCallback onToggleMembership;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF285F98), Color(0xFF1DAAE2)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33285F98),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(path: club.avatarAsset, size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '#${club.code} · المالك ${club.ownerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xDFFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            club.announcementText.isEmpty
                ? 'لا يوجد إعلان للنادي حالياً.'
                : club.announcementText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'الأعضاء',
                  value: '${club.membersCount}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(label: 'الغرف', value: '${club.roomsCount}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'النقاط',
                  value: '${club.rankingPoints}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: club.isOwner ? null : onToggleMembership,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE9EEF4),
              foregroundColor: HomeClubsScreen.primaryBlue,
              disabledForegroundColor: HomeClubsScreen.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    club.isOwner
                        ? 'أنت مالك النادي'
                        : (club.isMember ? 'مغادرة النادي' : 'انضم للنادي'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubQuickActions extends StatelessWidget {
  const _ClubQuickActions({required this.club});

  final ClubData club;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.mic_external_on_rounded,
            title: 'غرف النادي',
            subtitle: '${club.roomsCount} غرف نشطة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.emoji_events_rounded,
            title: 'الترتيب',
            subtitle: '${club.rankingPoints} نقطة',
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: HomeClubsScreen.primaryBlue, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeClubsScreen.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7F91A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _PostComposer extends StatelessWidget {
  const _PostComposer({
    required this.controller,
    required this.isPosting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('home-club-post-field'),
              controller: controller,
              textDirection: TextDirection.rtl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'اكتب إعلاناً لأعضاء النادي',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isPosting ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: HomeClubsScreen.primaryBlue,
              foregroundColor: Colors.white,
            ),
            icon: isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile(this.item);

  final ClubFeedItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(path: item.authorAvatarAsset, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeClubsScreen.primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      item.createdAtLabel,
                      style: const TextStyle(
                        color: Color(0xFF9AA8B9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item.bodyText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF536477),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final ClubMemberData member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _Avatar(path: member.avatarAsset, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeClubsScreen.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.joinedAtLabel,
                    style: const TextStyle(
                      color: Color(0xFF9AA8B9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _RoleBadge(role: member.role),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'owner' => 'مالك',
      'admin' => 'مشرف',
      _ => 'عضو',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: role == 'owner'
            ? const Color(0xFFFFE8B2)
            : const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: role == 'owner'
              ? const Color(0xFF9B6500)
              : HomeClubsScreen.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: HomeClubsScreen.primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FB),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: HomeClubsScreen.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: HomeClubsScreen.lightBlue, size: 44),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeClubsScreen.primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7F91A8),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _DetailHeader(onBack: onBack),
          const Spacer(),
          const Icon(
            Icons.error_outline_rounded,
            color: HomeClubsScreen.lightBlue,
            size: 64,
          ),
          const SizedBox(height: 12),
          const Text(
            'تعذر فتح النادي',
            style: TextStyle(
              color: HomeClubsScreen.primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7F91A8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeClubsScreen.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة المحاولة'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: ResolvedImage(
        path: path,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
