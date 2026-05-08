import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/club_repository.dart';

enum ClubListScope { trending, mine, newest }

class HomeClubsScreen extends StatefulWidget {
  const HomeClubsScreen({super.key});

  static const Color primaryBlue = Color(0xFF285F98);
  static const Color lightBlue = Color(0xFFB4D1EF);
  static const Color background = Color(0xFFF6F6F6);
  static const Color softField = Color(0xFFD6DEE9);

  @override
  State<HomeClubsScreen> createState() => _HomeClubsScreenState();
}

class _HomeClubsScreenState extends State<HomeClubsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ClubListScope _scope = ClubListScope.trending;
  late Future<List<ClubData>> _clubsFuture;

  @override
  void initState() {
    super.initState();
    _clubsFuture = _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ClubData>> _loadClubs() {
    return ClubRepository.instance.listClubs(
      scope: _scope.name,
      query: _searchController.text,
    );
  }

  Future<void> _refresh() async {
    final future = _loadClubs();
    setState(() {
      _clubsFuture = future;
    });
    await future;
  }

  void _setScope(ClubListScope scope) {
    if (_scope == scope) {
      return;
    }
    setState(() {
      _scope = scope;
      _clubsFuture = _loadClubs();
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.homeClubCreate);
    if (!mounted || created != true) {
      return;
    }
    await _refresh();
  }

  Future<void> _openClub(ClubData club) async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.homeClubDetail,
      arguments: HomeClubDetailScreenArgs(clubId: club.id),
    );
    if (!mounted || changed != true) {
      return;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HomeClubsScreen.background,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('home-club-create-fab'),
          onPressed: _openCreate,
          backgroundColor: HomeClubsScreen.primaryBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إنشاء نادي',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: HomeClubsScreen.primaryBlue,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ClubHeader(onBack: () => Navigator.of(context).pop()),
                        const SizedBox(height: 20),
                        _ClubSearchField(
                          controller: _searchController,
                          onSubmitted: (_) => _refresh(),
                          onClear: () {
                            _searchController.clear();
                            _refresh();
                          },
                        ),
                        const SizedBox(height: 14),
                        _ClubScopeTabs(
                          selectedScope: _scope,
                          onSelected: _setScope,
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<ClubData>>(
                  future: _clubsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: HomeClubsScreen.primaryBlue,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ClubStateMessage(
                          icon: Icons.wifi_off_rounded,
                          title: 'تعذر تحميل النوادي',
                          subtitle: snapshot.error.toString(),
                          actionLabel: 'إعادة المحاولة',
                          onAction: _refresh,
                        ),
                      );
                    }

                    final clubs = snapshot.data ?? const <ClubData>[];
                    if (clubs.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ClubStateMessage(
                          icon: Icons.groups_2_rounded,
                          title: 'لا توجد نوادي هنا حالياً',
                          subtitle: 'ابدأ ناديك أو جرّب البحث باسم مختلف.',
                          actionLabel: 'إنشاء نادي',
                          onAction: _openCreate,
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                      sliver: SliverList.separated(
                        itemCount: clubs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _ClubCard(
                            club: clubs[index],
                            rank: index + 1,
                            onTap: () => _openClub(clubs[index]),
                            onMembershipChanged: _refresh,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClubHeader extends StatelessWidget {
  const _ClubHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIcon(
          onTap: onBack,
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: HomeClubsScreen.primaryBlue,
            size: 18,
          ),
        ),
        const Spacer(),
        const Text(
          'النوادى',
          style: TextStyle(
            color: HomeClubsScreen.primaryBlue,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 42),
      ],
    );
  }
}

class _ClubSearchField extends StatelessWidget {
  const _ClubSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('home-clubs-search-field'),
      controller: controller,
      textDirection: TextDirection.rtl,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: HomeClubsScreen.primaryBlue,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'ابحث باسم النادي أو الرمز',
        hintStyle: const TextStyle(
          color: HomeClubsScreen.primaryBlue,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: HomeClubsScreen.primaryBlue,
        ),
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(
            Icons.close_rounded,
            color: HomeClubsScreen.primaryBlue,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _ClubScopeTabs extends StatelessWidget {
  const _ClubScopeTabs({required this.selectedScope, required this.onSelected});

  final ClubListScope selectedScope;
  final ValueChanged<ClubListScope> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScopeChip(
          label: 'الأقوى',
          active: selectedScope == ClubListScope.trending,
          onTap: () => onSelected(ClubListScope.trending),
        ),
        const SizedBox(width: 9),
        _ScopeChip(
          label: 'نواديك',
          active: selectedScope == ClubListScope.mine,
          onTap: () => onSelected(ClubListScope.mine),
        ),
        const SizedBox(width: 9),
        _ScopeChip(
          label: 'الأحدث',
          active: selectedScope == ClubListScope.newest,
          onTap: () => onSelected(ClubListScope.newest),
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? HomeClubsScreen.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active
                  ? HomeClubsScreen.primaryBlue
                  : const Color(0xFFE0E7F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : HomeClubsScreen.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClubCard extends StatefulWidget {
  const _ClubCard({
    required this.club,
    required this.rank,
    required this.onTap,
    required this.onMembershipChanged,
  });

  final ClubData club;
  final int rank;
  final VoidCallback onTap;
  final Future<void> Function() onMembershipChanged;

  @override
  State<_ClubCard> createState() => _ClubCardState();
}

class _ClubCardState extends State<_ClubCard> {
  bool _isBusy = false;

  Future<void> _toggleMembership() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      if (widget.club.isMember && !widget.club.isOwner) {
        await ClubRepository.instance.leaveClub(widget.club.id);
      } else if (!widget.club.isMember) {
        await ClubRepository.instance.joinClub(widget.club.id);
      }
      await widget.onMembershipChanged();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ClubAvatar(path: club.avatarAsset, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              club.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: HomeClubsScreen.primaryBlue,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RankBadge(rank: widget.rank),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${club.code}  ·  ${club.ownerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF7F91A8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              club.announcementText.isEmpty
                  ? 'لا يوجد إعلان للنادي حتى الآن.'
                  : club.announcementText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF536477),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _MetricPill(
                  icon: Icons.groups_2_rounded,
                  label: '${club.membersCount} عضو',
                ),
                _MetricPill(
                  icon: Icons.mic_rounded,
                  label: '${club.roomsCount} غرف',
                ),
                _MetricPill(
                  icon: Icons.workspace_premium_rounded,
                  label: '${club.rankingPoints} نقطة',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HomeClubsScreen.primaryBlue,
                      side: const BorderSide(color: HomeClubsScreen.lightBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'عرض النادي',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: club.isOwner ? null : _toggleMembership,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: club.isMember
                          ? const Color(0xFFE9EEF4)
                          : HomeClubsScreen.primaryBlue,
                      foregroundColor: club.isMember
                          ? HomeClubsScreen.primaryBlue
                          : Colors.white,
                      disabledBackgroundColor: const Color(0xFFE9EEF4),
                      disabledForegroundColor: HomeClubsScreen.primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            club.isOwner
                                ? 'مالك النادي'
                                : (club.isMember ? 'مغادرة' : 'انضمام'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8B2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: Color(0xFF9B6500),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FA),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HomeClubsScreen.primaryBlue, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: HomeClubsScreen.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubStateMessage extends StatelessWidget {
  const _ClubStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: HomeClubsScreen.lightBlue, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeClubsScreen.primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7F91A8),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeClubsScreen.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.onTap, required this.child});

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

class _ClubAvatar extends StatelessWidget {
  const _ClubAvatar({required this.path, required this.size});

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

class HomeClubDetailScreenArgs {
  const HomeClubDetailScreenArgs({required this.clubId});

  final int clubId;
}
