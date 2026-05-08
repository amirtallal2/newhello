import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/profile_economy_repository.dart';

class ProfileIncomeScreen extends StatefulWidget {
  const ProfileIncomeScreen({super.key});

  @override
  State<ProfileIncomeScreen> createState() => _ProfileIncomeScreenState();
}

class _ProfileIncomeScreenState extends State<ProfileIncomeScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);

  static const List<_IncomeMetric> _metrics = [
    _IncomeMetric(
      label: 'التقرير اليومي',
      value: '1822',
      kind: _MetricKind.coin,
    ),
    _IncomeMetric(
      label: 'التقرير الاسبوعي',
      value: '0',
      kind: _MetricKind.coin,
    ),
    _IncomeMetric(
      label: 'التقرير الشهري',
      value: '153',
      kind: _MetricKind.coin,
    ),
    _IncomeMetric(
      label: 'دقائق الروم الصوتي',
      value: '4min',
      kind: _MetricKind.text,
    ),
    _IncomeMetric(
      label: 'الهدايا المستلمة',
      value: '5',
      kind: _MetricKind.coin,
    ),
    _IncomeMetric(
      label: 'المكسب من الرسائل',
      value: '550',
      kind: _MetricKind.coin,
    ),
    _IncomeMetric(
      label: 'المكسب الاجمالي',
      value: '55550',
      kind: _MetricKind.coin,
    ),
    _IncomeMetric(
      label: 'المكفائات',
      value: 'min/100',
      kind: _MetricKind.mixed,
    ),
  ];

  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;
  int _coinsBalance = 2620;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final dashboard = await _economyRepository.loadWalletDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _coinsBalance = dashboard.wallet.coinsBalance;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/profile_connections_background.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: RefreshIndicator(
                color: _primaryBlue,
                onRefresh: _loadWallet,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(21, 60, 21, 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              label: 'profile-income-back',
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
                            'الدخل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Semantics(
                              label: 'profile-income-history',
                              button: true,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileIncomeHistory);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'History',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 4),
                                          blurRadius: 4,
                                          color: Color(0x40000000),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'الوقت المتبقي :',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '01d 02:21:45',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 333),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                        decoration: BoxDecoration(
                          color: _primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'عملاتي',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'عملاتي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Semantics(
                                  label: 'profile-income-card-action',
                                  button: true,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.profileWallet);
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _CoinAmountLabel(text: '$_coinsBalance = \$0'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'لم يستوف عتبة السحب بعد.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ..._metrics.map(
                              (metric) => Padding(
                                padding: const EdgeInsets.only(bottom: 13),
                                child: _IncomeMetricRow(metric: metric),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeMetricRow extends StatelessWidget {
  const _IncomeMetricRow({required this.metric});

  final _IncomeMetric metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricValue(metric: metric),
        const Spacer(),
        Text(
          metric.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({required this.metric});

  final _IncomeMetric metric;

  @override
  Widget build(BuildContext context) {
    switch (metric.kind) {
      case _MetricKind.coin:
        return _CoinAmountLabel(text: metric.value);
      case _MetricKind.text:
        return Text(
          metric.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      case _MetricKind.mixed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              metric.value.split('/').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(
              'assets/images/profile_income_dollar_icon.png',
              width: 14,
              height: 14,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 4),
            Text(
              '/${metric.value.split('/').last}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}

class _CoinAmountLabel extends StatelessWidget {
  const _CoinAmountLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 5),
        Image.asset(
          'assets/images/profile_income_dollar_icon.png',
          width: 14,
          height: 14,
          filterQuality: FilterQuality.high,
        ),
      ],
    );
  }
}

class _IncomeMetric {
  const _IncomeMetric({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String value;
  final _MetricKind kind;
}

enum _MetricKind { coin, text, mixed }
