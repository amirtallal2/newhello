import 'package:flutter/material.dart';

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

  static const List<_ShippingAgencyData> _allAgencies = [
    _ShippingAgencyData(
      name: 'Mohamed Ahmed',
      handle: '@ ابو احمد',
      amount: '30.5M',
      supportedCountriesCount: 7,
      supportedFlags: [_FlagType.austria, _FlagType.azerbaijan, _FlagType.uae],
    ),
    _ShippingAgencyData(
      name: 'Mohamed Ahmed',
      handle: '@ ابو احمد',
      amount: '30.5M',
      supportedCountriesCount: 7,
      supportedFlags: [_FlagType.austria, _FlagType.azerbaijan, _FlagType.uae],
    ),
    _ShippingAgencyData(
      name: 'Mohamed Ahmed',
      handle: '@ ابو احمد',
      amount: '30.5M',
      supportedCountriesCount: 7,
      supportedFlags: [_FlagType.austria, _FlagType.azerbaijan, _FlagType.uae],
    ),
    _ShippingAgencyData(
      name: 'Mohamed Ahmed',
      handle: '@ ابو احمد',
      amount: '30.5M',
      supportedCountriesCount: 7,
      supportedFlags: [_FlagType.austria, _FlagType.azerbaijan, _FlagType.uae],
    ),
    _ShippingAgencyData(
      name: 'Mohamed Ahmed',
      handle: '@ ابو احمد',
      amount: '30.5M',
      supportedCountriesCount: 7,
      supportedFlags: [_FlagType.austria, _FlagType.azerbaijan, _FlagType.uae],
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _submittedQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _submittedQuery.trim().toLowerCase();
    final agencies = query.isEmpty
        ? _allAgencies
        : _allAgencies.where((agency) {
            final combined = '${agency.name} ${agency.handle} ${agency.amount}'
                .toLowerCase();
            return combined.contains(query);
          }).toList();

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
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 14),
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
                            width: 38,
                            height: 38,
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
                      'وكالة الشحن',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 0, 21, 15),
                child: Row(
                  children: [
                    SizedBox(
                      width: 87,
                      height: 52,
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
                        child: const Text(
                          'بحث',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _surfaceGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: TextField(
                          key: const ValueKey('profile-shipping-agency-field'),
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
              Expanded(
                child: agencies.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: agencies.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 1),
                        itemBuilder: (context, index) {
                          return _ShippingAgencyCard(
                            agency: agencies[index],
                            index: index,
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

  void _submitSearch() {
    setState(() {
      _submittedQuery = _searchController.text;
    });
  }
}

class _ShippingAgencyCard extends StatelessWidget {
  const _ShippingAgencyCard({required this.agency, required this.index});

  final _ShippingAgencyData agency;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('profile-shipping-agency-card-$index'),
      color: _ProfileShippingAgencyScreenState._surfaceGrey,
      padding: const EdgeInsets.fromLTRB(19, 11, 19, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFD7E5F6),
                child: Text(
                  agency.name.characters.first,
                  style: const TextStyle(
                    color: _ProfileShippingAgencyScreenState._primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      agency.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agency.handle,
                      style: const TextStyle(
                        color: _ProfileShippingAgencyScreenState._handleGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agency.amount,
                    style: const TextStyle(
                      color: _ProfileShippingAgencyScreenState._amountGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/profile_wallet_diamond_small.png',
                    width: 25,
                    height: 25,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    const Text(
                      '>',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${agency.supportedCountriesCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...agency.supportedFlags.map(
                      (flag) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _FlagBadge(flag: flag),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'الدول المدعومة للتداول',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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

class _ShippingAgencyData {
  const _ShippingAgencyData({
    required this.name,
    required this.handle,
    required this.amount,
    required this.supportedCountriesCount,
    required this.supportedFlags,
  });

  final String name;
  final String handle;
  final String amount;
  final int supportedCountriesCount;
  final List<_FlagType> supportedFlags;
}

enum _FlagType { austria, azerbaijan, uae }
