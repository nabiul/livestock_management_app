import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class ProfessionalReportsScreen extends StatefulWidget {
  const ProfessionalReportsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ProfessionalReportsScreen> createState() =>
      _ProfessionalReportsScreenState();
}

class _ProfessionalReportsScreenState extends State<ProfessionalReportsScreen> {
  Map<String, dynamic> data = {};
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime.now();
  List<Map<String, dynamic>> farms = [];
  int? farmId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      data = widget.api.objectFrom(
        await widget.api.get(
          'reports',
          query: {
            'from': dateFormat.format(from),
            'to': dateFormat.format(to),
            if (farmId != null) 'farm_id': farmId,
          },
        ),
      );
      farms = widget.api.listFrom(_map(data['filter_options'])['farms']);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    final profit = _map(data['profit_loss']);
    final cash = _map(data['cash_flow']);
    final sales = _map(data['sales']);
    final purchases = _map(data['purchases']);
    final inventory = _map(data['inventory']);
    final livestock = _map(data['livestock_batches']);
    final health = _map(data['health']);
    final production = _map(data['production']);
    final productionSources = _list(production['by_source']);
    final trend = _list(data['trend']);
    final lowStock = _list(inventory['low_stock']);
    final upcoming = _list(health['upcoming']);
    final parties = _list(data['party_balances']);
    final livestockProfitability = _map(data['livestock_profitability']);
    final individualProfit = _map(livestockProfitability['individual']);
    final batchProfit = _map(livestockProfitability['batches']);
    final catalog = _list(data['report_catalog']);
    final specialized = _map(data['specialized_reports']);

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _hero(_num(profit['net'])),
          const SizedBox(height: 12),
          _filters(),
          if (catalog.isNotEmpty) ...[
            const SizedBox(height: 14),
            _reportDirectory(catalog, specialized),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, size) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: size.maxWidth >= 850 ? 4 : 2,
                childAspectRatio: size.maxWidth >= 600 ? 1.75 : 1.25,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _metric(
                    'Total income',
                    profit['income'],
                    Icons.south_west,
                    const Color(0xFF178455),
                  ),
                  _metric(
                    'Total expense',
                    profit['expense'],
                    Icons.north_east,
                    const Color(0xFFE06A3B),
                  ),
                  _metric(
                    'Cash received',
                    cash['in'],
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF2F6FED),
                  ),
                  _metric(
                    'Cash paid',
                    cash['out'],
                    Icons.payments_outlined,
                    const Color(0xFF7A56C2),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _incomeExpense(profit),
          if (trend.isNotEmpty) ...[const SizedBox(height: 14), _trend(trend)],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, size) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _summary(
                    size,
                    'Sales',
                    Icons.point_of_sale,
                    const Color(0xFF178455),
                    [
                      ('Invoices', '${sales['count'] ?? 0}'),
                      ('Total', _money(sales['total'])),
                      ('Outstanding', _money(sales['due'])),
                    ],
                  ),
                  _summary(
                    size,
                    'Purchases',
                    Icons.shopping_cart_outlined,
                    const Color(0xFFE06A3B),
                    [
                      ('Invoices', '${purchases['count'] ?? 0}'),
                      ('Total', _money(purchases['total'])),
                      ('Outstanding', _money(purchases['due'])),
                    ],
                  ),
                  _summary(
                    size,
                    'Inventory',
                    Icons.inventory_2_outlined,
                    const Color(0xFF2F6FED),
                    [
                      ('Items', '${inventory['item_count'] ?? 0}'),
                      ('Stock value', _money(inventory['value'])),
                      ('Low stock', '${lowStock.length}'),
                    ],
                  ),
                  _summary(
                    size,
                    'Livestock batches',
                    Icons.groups_2_outlined,
                    const Color(0xFF7A56C2),
                    [
                      ('Batches', '${livestock['batch_count'] ?? 0}'),
                      ('Available', '${livestock['available'] ?? 0} head'),
                      ('Stock value', _money(livestock['stock_value'])),
                    ],
                  ),
                  _summary(
                    size,
                    'Health',
                    Icons.medical_services_outlined,
                    const Color(0xFFD45672),
                    [
                      ('Records', '${health['records'] ?? 0}'),
                      ('Cost', _money(health['cost'])),
                      ('Upcoming', '${upcoming.length}'),
                    ],
                  ),
                  _summary(
                    size,
                    'Production',
                    Icons.egg_alt_outlined,
                    const Color(0xFFB17418),
                    [
                      ('Records', '${production['records'] ?? 0}'),
                      (
                        'Estimated value',
                        _money(production['estimated_value']),
                      ),
                      ('Sources', '${productionSources.length}'),
                    ],
                  ),
                ],
              );
            },
          ),
          if (productionSources.isNotEmpty) ...[
            const SizedBox(height: 14),
            _productionSources(productionSources),
          ],
          if (_list(individualProfit['items']).isNotEmpty ||
              _list(batchProfit['items']).isNotEmpty) ...[
            const SizedBox(height: 14),
            _livestockProfit(
              'Individual livestock profitability',
              individualProfit,
              false,
            ),
            const SizedBox(height: 14),
            _livestockProfit(
              'Batch-wise livestock profitability',
              batchProfit,
              true,
            ),
          ],
          if (lowStock.isNotEmpty || upcoming.isNotEmpty) ...[
            const SizedBox(height: 14),
            _attention(lowStock, upcoming),
          ],
          if (parties.isNotEmpty) ...[
            const SizedBox(height: 14),
            _parties(parties),
          ],
        ],
      ),
    );
  }

  Widget _hero(num net) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123F2C), Color(0xFF1F7850)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x25123F2C),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BUSINESS PERFORMANCE',
                style: TextStyle(
                  color: Color(0xFFB9E6CF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _money(net),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                net >= 0
                    ? 'Net profit for selected period'
                    : 'Net loss for selected period',
                style: const TextStyle(color: Color(0xFFDCEEE4)),
              ),
            ],
          ),
        ),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            net >= 0 ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    ),
  );

  Widget _reportDirectory(
    List<Map<String, dynamic>> catalog,
    Map<String, dynamic> reports,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Report directory',
            subtitle: '${catalog.length} detailed operational reports',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 480
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 9)) / columns;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (var index = 0; index < catalog.length; index++)
                    SizedBox(
                      width: width,
                      child: _reportLink(
                        index + 1,
                        catalog[index],
                        _map(reports[catalog[index]['key']]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _reportLink(
    int number,
    Map<String, dynamic> catalog,
    Map<String, dynamic> report,
  ) => Material(
    color: const Color(0xFFF8FBF9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE5ECE8)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              SpecializedReportScreen(report: report, number: number),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _reportColor(number).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _reportIcon('${catalog['key']}'),
                color: _reportColor(number),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. ${catalog['title']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF173B2A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${catalog['row_count'] ?? 0} records',
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA6B1AB),
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );

  Color _reportColor(int index) => const [
    Color(0xFF07883F),
    Color(0xFF2775D8),
    Color(0xFFD9820B),
    Color(0xFF8946D8),
    Color(0xFFD9443A),
  ][index % 5];

  IconData _reportIcon(String key) => switch (key) {
    'animal_history' => Icons.history,
    'animal_age' => Icons.cake_outlined,
    'breed' => Icons.pets_outlined,
    'birth' || 'calving' => Icons.child_friendly_outlined,
    'death' => Icons.heart_broken_outlined,
    'purchase_sale' => Icons.swap_horiz,
    'weight_growth' => Icons.monitor_weight_outlined,
    'breeding' => Icons.favorite_outline,
    'pregnancy' => Icons.pregnant_woman,
    'vaccination' => Icons.vaccines_outlined,
    'disease' || 'treatment_cost' => Icons.medical_services_outlined,
    'milk_production' || 'lactation' => Icons.water_drop_outlined,
    'feed_consumption' || 'feed_cost' => Icons.grass_outlined,
    'inventory' => Icons.inventory_2_outlined,
    'employee' => Icons.badge_outlined,
    'income_expense' => Icons.account_balance_wallet_outlined,
    'animal_profitability' ||
    'farm_profitability' => Icons.trending_up_outlined,
    _ => Icons.analytics_outlined,
  };

  Widget _filters() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _date('From', from, (value) => from = value)),
              const SizedBox(width: 8),
              Expanded(child: _date('To', to, (value) => to = value)),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: load,
                tooltip: 'Apply',
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SearchableDropdown(
            key: ValueKey('report-farm:$farmId'),
            label: 'Farm',
            items: farms,
            value: farmId,
            emptyLabel: 'All farms',
            onChanged: (value) => setState(() => farmId = value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _preset(
                  'This month',
                  DateTime(DateTime.now().year, DateTime.now().month, 1),
                ),
                _preset(
                  'Last 30 days',
                  DateTime.now().subtract(const Duration(days: 29)),
                ),
                _preset('This year', DateTime(DateTime.now().year)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _preset(String label, DateTime start) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          from = start;
          to = DateTime.now();
        });
        load();
      },
    ),
  );

  Widget _metric(String label, dynamic value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Text(
                _money(value),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );

  Widget _incomeExpense(Map<String, dynamic> values) {
    final maximum = [
      _num(values['income']),
      _num(values['expense']),
      1,
    ].reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Income vs expense',
              subtitle: 'Revenue and cost composition',
            ),
            _bar(
              'Sales income',
              values['sales_income'],
              maximum,
              const Color(0xFF178455),
            ),
            _bar(
              'Other income',
              values['other_income'],
              maximum,
              const Color(0xFF57B889),
            ),
            _bar(
              'Purchases',
              values['purchase_expense'],
              maximum,
              const Color(0xFFE06A3B),
            ),
            _bar(
              'Other expense',
              values['other_expense'],
              maximum,
              const Color(0xFFF0A078),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, dynamic raw, num maximum, Color color) {
    final value = _num(raw);
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                _money(value),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (value / maximum).clamp(0, 1).toDouble(),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trend(List<Map<String, dynamic>> months) {
    final maximum = months.fold<num>(1, (current, month) {
      final value = [
        _num(month['income']),
        _num(month['expense']),
      ].reduce((a, b) => a > b ? a : b);
      return value > current ? value : current;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Monthly trend',
              subtitle: 'Income and expense movement',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: months
                    .map(
                      (month) => SizedBox(
                        width: 82,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 120,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _column(
                                    month['income'],
                                    maximum,
                                    const Color(0xFF178455),
                                  ),
                                  const SizedBox(width: 5),
                                  _column(
                                    month['expense'],
                                    maximum,
                                    const Color(0xFFE06A3B),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${month['label']}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 18,
              children: [
                _Legend(Color(0xFF178455), 'Income'),
                _Legend(Color(0xFFE06A3B), 'Expense'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _column(dynamic raw, num maximum, Color color) {
    final value = _num(raw);
    return Tooltip(
      message: _money(value),
      child: Container(
        width: 22,
        height: 8 + (value / maximum * 110).clamp(0, 110).toDouble(),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
        ),
      ),
    );
  }

  Widget _summary(
    BoxConstraints size,
    String title,
    IconData icon,
    Color color,
    List<(String, String)> rows,
  ) {
    final width = size.maxWidth >= 850
        ? (size.maxWidth - 24) / 3
        : size.maxWidth >= 560
        ? (size.maxWidth - 12) / 2
        : size.maxWidth;
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Flexible(
                        child: Text(
                          row.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productionSources(List<Map<String, dynamic>> sources) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Production by livestock source',
            subtitle: 'Individual, batch and farm-level output',
          ),
          for (final source in sources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Icon(
                  source['source_type'] == 'individual'
                      ? Icons.pets_outlined
                      : source['source_type'] == 'batch'
                      ? Icons.groups_2_outlined
                      : Icons.home_work_outlined,
                ),
              ),
              title: Text(
                '${source['source'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${source['source_type'] ?? 'farm'} · ${source['outputs'] ?? ''}',
              ),
              trailing: Text(
                _money(source['estimated_value']),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _attention(
    List<Map<String, dynamic>> stock,
    List<Map<String, dynamic>> health,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Needs attention',
            subtitle: 'Low stock and upcoming health schedules',
          ),
          for (final item in stock.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.inventory_2_outlined),
              ),
              title: Text('${item['name']}'),
              subtitle: Text('${item['quantity']} ${item['unit']} remaining'),
              trailing: const StatusChip('low stock'),
            ),
          for (final record in health.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.medical_services_outlined),
              ),
              title: Text('${record['title']}'),
              subtitle: Text(
                '${record['animal']?['tag_number'] ?? 'Animal'} · Due ${formatAppDate(record['next_due_date'])}',
              ),
            ),
        ],
      ),
    ),
  );

  Widget _livestockProfit(
    String title,
    Map<String, dynamic> summary,
    bool batch,
  ) {
    final items = _list(summary['items']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              subtitle: 'Purchase, sale and linked accounting entries',
            ),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _profitTotal('Income', summary['income'], Colors.green),
                _profitTotal('Expense', summary['expense'], Colors.orange),
                _profitTotal(
                  'Net',
                  summary['net'],
                  _num(summary['net']) >= 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const Divider(height: 28),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No linked livestock transactions in this period.'),
              ),
            for (final item in items)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                leading: CircleAvatar(
                  child: Icon(batch ? Icons.groups_2_outlined : Icons.pets),
                ),
                title: Text(
                  batch
                      ? '${item['batch_code']}'
                      : '${item['tag_number']} ${item['name'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${item['species'] ?? 'Livestock'} · ${item['farm'] ?? 'Farm'}${batch ? ' · ${item['available']} available' : ' · ${item['status']}'}',
                ),
                trailing: Text(
                  _money(item['net']),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _num(item['net']) >= 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                children: [
                  _profitRow('Sale income', item['sale_income']),
                  _profitRow('Other income', item['other_income']),
                  _profitRow('Purchase cost', item['purchase_cost']),
                  _profitRow('Other expense', item['other_expense']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _profitTotal(String label, dynamic value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          _money(value),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _profitRow(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          _money(value),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _parties(List<Map<String, dynamic>> parties) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Party balances',
            subtitle: 'Outstanding customer and vendor balances',
          ),
          for (final party in parties.take(10))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text('${party['name']}'),
              subtitle: Text('${party['type']}'),
              trailing: Text(
                _money(party['balance']),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _num(party['balance']) >= 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _date(String label, DateTime value, ValueChanged<DateTime> change) =>
      OutlinedButton.icon(
        onPressed: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (selected != null) setState(() => change(selected));
        },
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10)),
            Text(
              displayDateFormat.format(value),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.map((item) => Map<String, dynamic>.from(item as Map)).toList()
      : [];
  num _num(dynamic value) => num.tryParse('$value') ?? 0;
  String _money(dynamic value) => moneyFormat.format(_num(value));
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class SpecializedReportScreen extends StatelessWidget {
  const SpecializedReportScreen({
    super.key,
    required this.report,
    required this.number,
  });

  final Map<String, dynamic> report;
  final int number;

  Map<String, dynamic> get summary => report['summary'] is Map
      ? Map<String, dynamic>.from(report['summary'] as Map)
      : {};
  Map<String, dynamic> get columns => report['columns'] is Map
      ? Map<String, dynamic>.from(report['columns'] as Map)
      : {};
  List<Map<String, dynamic>> get rows => report['rows'] is List
      ? (report['rows'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : [];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${report['title'] ?? 'Report'}')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF076F37), Color(0xFF2FA65C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report['title'] ?? 'Report'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report['description'] ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in summary.entries)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5ECE8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Color(0xFF718078),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _reportValue(entry.key, entry.value),
                        style: const TextStyle(
                          color: Color(0xFF173B2A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Report records',
              style: TextStyle(
                color: Color(0xFF173B2A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${rows.length} entries',
              style: const TextStyle(color: Color(0xFF718078), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const SizedBox(
            height: 240,
            child: EmptyView(
              icon: Icons.analytics_outlined,
              message: 'No records found for this period.',
            ),
          )
        else
          for (final row in rows) _rowCard(row),
      ],
    ),
  );

  Widget _rowCard(Map<String, dynamic> row) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5ECE8)),
    ),
    child: Column(
      children: [
        for (final entry in columns.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 105,
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _reportValue(entry.key, row[entry.key]),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF173B2A),
                      fontSize: 12,
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

  static String _reportValue(String key, dynamic value) {
    if (value == null || '$value'.isEmpty) return '—';
    final normalized = key.toLowerCase().replaceAll(' ', '_');
    final monetary =
        normalized.contains('cost') ||
        normalized.contains('income') ||
        normalized.contains('expense') ||
        normalized.contains('profit') ||
        normalized.contains('value') ||
        normalized == 'amount' ||
        normalized == 'total' ||
        normalized == 'paid' ||
        normalized == 'due' ||
        normalized == 'net';
    if (monetary && num.tryParse('$value') != null) {
      return moneyFormat.format(num.parse('$value'));
    }
    return '$value';
  }
}
