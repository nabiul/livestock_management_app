import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = widget.api.objectFrom(await widget.api.get('dashboard'));
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final data = _data ?? {};
    final stats = [
      ('Farms', data['farms'] ?? 0, Icons.home_work_outlined),
      ('Active livestock', data['active_animals'] ?? 0, Icons.pets_outlined),
      ('Health due', data['health_due'] ?? 0, Icons.medical_services_outlined),
      ('Low stock', data['low_stock_items'] ?? 0, Icons.inventory_2_outlined),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 350;
              return Container(
                constraints: const BoxConstraints(minHeight: 142),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF076F37), Color(0xFF2FA65C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26036D31),
                      blurRadius: 22,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      right: -34,
                      top: -52,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .07),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 48,
                      bottom: -64,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(compact ? 16 : 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color(0xFF9DF1B7),
                                        size: 7,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'LIVE FARM OVERVIEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Healthy livestock.\nProfitable future.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 19 : 22,
                                    height: 1.13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Everything important, in one place',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .82),
                                    fontSize: compact ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: compact ? 62 : 76,
                            height: compact ? 62 : 76,
                            padding: EdgeInsets.all(compact ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .96),
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .8),
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/livestockos-logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Farm summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Text(
                'Live data',
                style: TextStyle(
                  color: Color(0xFF07883F),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
              mainAxisExtent: 104,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
            ),
            itemCount: stats.length,
            itemBuilder: (_, index) {
              final stat = stats[index];
              final colors = const [
                (Color(0xFFDFF5E7), Color(0xFF07883F)),
                (Color(0xFFE6F1FF), Color(0xFF2775D8)),
                (Color(0xFFFFE7E5), Color(0xFFE3493F)),
                (Color(0xFFFFF0D7), Color(0xFFE99218)),
              ][index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: colors.$1,
                        child: Icon(stat.$3, color: colors.$2, size: 21),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.$1,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Color(0xFF617066),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${stat.$2}',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'This month',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _moneyTile(
                          context,
                          'Total income',
                          data['month_income'],
                          Icons.account_balance_wallet_outlined,
                          const Color(0xFF07883F),
                          const Color(0xFFDFF5E7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _moneyTile(
                          context,
                          'Total expense',
                          data['month_expense'],
                          Icons.receipt_long_outlined,
                          const Color(0xFFE3493F),
                          const Color(0xFFFFE7E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F7EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.trending_up,
                            color: Color(0xFF07883F),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Net balance',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          moneyFormat.format(
                            num.tryParse('${data['month_balance']}') ?? 0,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF07883F),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyTile(
    BuildContext context,
    String label,
    dynamic value,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            moneyFormat.format(num.tryParse('$value') ?? 0),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
