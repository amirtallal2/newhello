import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/responsive.dart';
import '../../data/profile_support_repository.dart';

class ProfileShippingAgencyScreen extends StatefulWidget {
  const ProfileShippingAgencyScreen({super.key});

  @override
  State<ProfileShippingAgencyScreen> createState() =>
      _ProfileShippingAgencyScreenState();
}

class _ProfileShippingAgencyScreenState
    extends State<ProfileShippingAgencyScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF5F5F5);
  static const Color _mutedGrey = Color(0xFFC8C8C8);
  static const Color _handleGold = Color(0xFFFFAE00);
  static const Color _amountGrey = Color(0xFF8E8E93);

  final ProfileSupportRepository _repository =
      ProfileSupportRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  List<ShippingAgencyData> _agencies = const <ShippingAgencyData>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _submittedQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  metrics.pageHorizontalPadding(compact: 14, regular: 20),
                  metrics.spacing(60, min: 42, max: 64),
                  metrics.pageHorizontalPadding(compact: 14, regular: 20),
                  metrics.spacing(14, min: 12, max: 16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: 'profile-shipping-agency-back',
                        button: true,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(19),
                          child: Container(
                            width: metrics.spacing(38, min: 34, max: 42),
                            height: metrics.spacing(38, min: 34, max: 42),
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
                    Text(
                      'وكالة الشحن',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: metrics.font(20, min: 18, max: 22),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.pageHorizontalPadding(compact: 14, regular: 21),
                  0,
                  metrics.pageHorizontalPadding(compact: 14, regular: 21),
                  metrics.spacing(15, min: 12, max: 16),
                ),
                child: ResponsiveContent(
                  maxWidth: 500,
                  child: Row(
                    children: [
                      SizedBox(
                        width: metrics.spacing(87, min: 74, max: 92),
                        height: metrics.spacing(52, min: 48, max: 54),
                        child: ElevatedButton(
                          key: const ValueKey('profile-shipping-agency-search'),
                          onPressed: _submitSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _surfaceGrey,
                            foregroundColor: _primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'بحث',
                            style: TextStyle(
                              fontSize: metrics.font(15, min: 13, max: 16),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: metrics.spacing(9, min: 8, max: 10)),
                      Expanded(
                        child: Container(
                          height: metrics.spacing(52, min: 48, max: 54),
                          decoration: BoxDecoration(
                            color: _surfaceGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            key: const ValueKey(
                              'profile-shipping-agency-field',
                            ),
                            controller: _searchController,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              hintText: 'ادخل معرف المستخدم او معرف خاص',
                              hintStyle: TextStyle(
                                color: _mutedGrey,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(
                              color: _primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            onSubmitted: (_) {
                              _submitSearch();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_errorMessage != null) {
                      return _RefreshableShippingMessage(
                        onRefresh: _loadAgencies,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadAgencies,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_agencies.isEmpty) {
                      return _RefreshableShippingMessage(
                        onRefresh: _loadAgencies,
                        child: const Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: _primaryBlue,
                      onRefresh: _loadAgencies,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: metrics.pageHorizontalPadding(
                            compact: 10,
                            regular: 16,
                          ),
                        ),
                        itemCount: _agencies.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 1),
                        itemBuilder: (context, index) {
                          return _ShippingAgencyCard(
                            agency: _agencies[index],
                            index: index,
                          );
                        },
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

  Future<void> _loadAgencies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agencies = await _repository.listShippingAgencies(
        query: _submittedQuery,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _agencies = agencies;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _submitSearch() {
    setState(() {
      _submittedQuery = _searchController.text;
    });
    _loadAgencies();
  }
}

class _RefreshableShippingMessage extends StatelessWidget {
  const _RefreshableShippingMessage({
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _ProfileShippingAgencyScreenState._primaryBlue,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _ShippingAgencyCard extends StatelessWidget {
  const _ShippingAgencyCard({required this.agency, required this.index});

  final ShippingAgencyData agency;
  final int index;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final supportedFlags = agency.supportedCountryCodes
        .map(_flagFromCountryCode)
        .whereType<_FlagType>()
        .take(3)
        .toList();

    return Semantics(
      label: 'profile-shipping-agency-card-$index',
      button: true,
      child: InkWell(
        onTap: () => _showAgencyActions(context, agency),
        child: Container(
          key: ValueKey('profile-shipping-agency-card-$index'),
          color: _ProfileShippingAgencyScreenState._surfaceGrey,
          padding: EdgeInsets.fromLTRB(
            metrics.spacing(19, min: 14, max: 20),
            metrics.spacing(11, min: 10, max: 12),
            metrics.spacing(19, min: 14, max: 20),
            metrics.spacing(8, min: 8, max: 10),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: metrics.spacing(26, min: 22, max: 28),
                    backgroundColor: const Color(0xFFD7E5F6),
                    child: Text(
                      agency.name.characters.first,
                      style: TextStyle(
                        color: _ProfileShippingAgencyScreenState._primaryBlue,
                        fontSize: metrics.font(22, min: 18, max: 22),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.spacing(10, min: 8, max: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          agency.name,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: metrics.font(16, min: 14, max: 17),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: metrics.spacing(4, min: 3, max: 5)),
                        Text(
                          agency.handle,
                          style: TextStyle(
                            color:
                                _ProfileShippingAgencyScreenState._handleGold,
                            fontSize: metrics.font(14, min: 12, max: 15),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: metrics.spacing(8, min: 6, max: 8)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        agency.diamondBalanceLabel,
                        style: TextStyle(
                          color: _ProfileShippingAgencyScreenState._amountGrey,
                          fontSize: metrics.font(14, min: 12, max: 15),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: metrics.spacing(4, min: 2, max: 4)),
                      Image.asset(
                        'assets/images/profile_wallet_diamond_small.png',
                        width: metrics.spacing(25, min: 22, max: 26),
                        height: metrics.spacing(25, min: 22, max: 26),
                        filterQuality: FilterQuality.high,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: metrics.spacing(10, min: 8, max: 10)),
              Container(
                width: double.infinity,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              SizedBox(height: metrics.spacing(8, min: 6, max: 8)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'الدول المدعومة للتداول',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: metrics.font(10, min: 9, max: 11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.spacing(8, min: 6, max: 10)),
                  Flexible(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Wrap(
                        spacing: metrics.spacing(6, min: 4, max: 6),
                        runSpacing: metrics.spacing(4, min: 3, max: 4),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '>',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: metrics.font(10, min: 9, max: 11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${agency.supportedCountriesCount}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: metrics.font(10, min: 9, max: 11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ...supportedFlags.map(
                            (flag) => _FlagBadge(flag: flag),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAgencyActions(
    BuildContext context,
    ShippingAgencyData agency,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E5F6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    agency.name,
                    style: const TextStyle(
                      color: _ProfileShippingAgencyScreenState._primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    agency.handle,
                    style: const TextStyle(
                      color: _ProfileShippingAgencyScreenState._handleGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ShippingActionTile(
                    icon: Icons.copy_rounded,
                    label: 'نسخ معرف الوكالة',
                    onTap: () {
                      _copyAndClose(
                        context,
                        sheetContext,
                        agency.handle,
                        'تم نسخ معرف الوكالة',
                      );
                    },
                  ),
                  _ShippingActionTile(
                    icon: Icons.badge_rounded,
                    label: 'نسخ اسم الوكالة',
                    onTap: () {
                      _copyAndClose(
                        context,
                        sheetContext,
                        agency.name,
                        'تم نسخ اسم الوكالة',
                      );
                    },
                  ),
                  _ShippingActionTile(
                    icon: Icons.public_rounded,
                    label: 'الدول المدعومة: ${agency.supportedCountriesCount}',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyAndClose(
    BuildContext context,
    BuildContext sheetContext,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ShippingActionTile extends StatelessWidget {
  const _ShippingActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: _ProfileShippingAgencyScreenState._primaryBlue,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: _ProfileShippingAgencyScreenState._primaryBlue,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.flag});

  final _FlagType flag;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 22,
        height: 16,
        child: switch (flag) {
          _FlagType.austria => const Column(
            children: [
              Expanded(child: ColoredBox(color: Color(0xFFF93939))),
              Expanded(child: ColoredBox(color: Colors.white)),
              Expanded(child: ColoredBox(color: Color(0xFFF93939))),
            ],
          ),
          _FlagType.uae => Row(
            children: const [
              SizedBox(width: 5, child: ColoredBox(color: Color(0xFFF93939))),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: ColoredBox(color: Color(0xFF249F58))),
                    Expanded(child: ColoredBox(color: Colors.white)),
                    Expanded(child: ColoredBox(color: Color(0xFF151515))),
                  ],
                ),
              ),
            ],
          ),
          _FlagType.azerbaijan => Stack(
            children: [
              const Column(
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFF3ECBF8))),
                  Expanded(child: ColoredBox(color: Color(0xFFF93939))),
                  Expanded(child: ColoredBox(color: Color(0xFF249F58))),
                ],
              ),
              Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

_FlagType? _flagFromCountryCode(String code) {
  return switch (code.toLowerCase()) {
    'at' => _FlagType.austria,
    'az' => _FlagType.azerbaijan,
    'ae' => _FlagType.uae,
    _ => null,
  };
}

enum _FlagType { austria, azerbaijan, uae }
