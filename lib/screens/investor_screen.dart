import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';
import 'generic/resource_screen.dart';

const investorFields = [
  FieldSpec('name', 'Investor name', required: true),
  FieldSpec('phone', 'Phone'),
  FieldSpec('email', 'Email'),
  FieldSpec('nid', 'NID / identification'),
  FieldSpec('address', 'Address', type: FieldType.multiline),
  FieldSpec(
    'status',
    'Status',
    type: FieldType.select,
    options: ['active', 'inactive'],
    defaultValue: 'active',
    required: true,
  ),
];

class InvestorsScreen extends StatefulWidget {
  const InvestorsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<InvestorsScreen> createState() => _InvestorsScreenState();
}

class _InvestorsScreenState extends State<InvestorsScreen> {
  List<Map<String, dynamic>> investors = [];
  Map<String, dynamic> summary = {};
  bool loading = true;
  String query = '';
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final response = await widget.api.get('investors');
      investors = widget.api.listFrom(response);
      summary = response is Map && response['summary'] is Map
          ? Map<String, dynamic>.from(response['summary'] as Map)
          : {};
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Map<String, dynamic>? investor]) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: investor == null ? 'Add investor' : 'Edit investor',
      child: ResourceForm(
        api: widget.api,
        endpoint: 'investors',
        fields: investorFields,
        initial: investor,
      ),
    );
    if (saved == true) load();
  }

  Future<void> remove(Map<String, dynamic> investor) async {
    final confirmed = await confirmAction(
      context,
      'Delete investor',
      'Investors with transaction history cannot be deleted.',
    );
    if (!confirmed) return;
    try {
      await widget.api.delete('investors/${investor['id']}');
      if (mounted) showMessage(context, 'Investor deleted.');
      load();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  Future<void> open(Map<String, dynamic> investor) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvestorDetailScreen(
          api: widget.api,
          investorId: investor['id'] as int,
          investorName: '${investor['name']}',
        ),
      ),
    );
    if (mounted) load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = investors.where((investor) {
      final matchesFilter = filter == 'all' || investor['status'] == filter;
      final text =
          '${investor['name']} ${investor['phone'] ?? ''} ${investor['email'] ?? ''}'
              .toLowerCase();
      return matchesFilter && text.contains(query.toLowerCase());
    }).toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: load,
          child: loading
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ownership overview',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: load,
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            context,
                            'Capital',
                            moneyFormat.format(
                              num.tryParse('${summary['total_capital']}') ?? 0,
                            ),
                            Icons.account_balance_wallet_outlined,
                            const Color(0xFFDFF5E7),
                            const Color(0xFF07883F),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _summaryCard(
                            context,
                            'Shares',
                            '${summary['total_shares'] ?? 0}',
                            Icons.pie_chart_outline,
                            const Color(0xFFE6F1FF),
                            const Color(0xFF2775D8),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            context,
                            'Investors',
                            '${summary['total_investors'] ?? 0}',
                            Icons.groups_outlined,
                            const Color(0xFFFFF0D7),
                            const Color(0xFFE99218),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _summaryCard(
                            context,
                            'Profit paid',
                            moneyFormat.format(
                              num.tryParse(
                                    '${summary['total_profit_distributed']}',
                                  ) ??
                                  0,
                            ),
                            Icons.payments_outlined,
                            const Color(0xFFF0E5FF),
                            const Color(0xFF8946D8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search investor...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'active', label: Text('Active')),
                        ButtonSegment(
                          value: 'inactive',
                          label: Text('Inactive'),
                        ),
                      ],
                      selected: {filter},
                      onSelectionChanged: (value) =>
                          setState(() => filter = value.first),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 8),
                      child: Text(
                        '${visible.length} ${visible.length == 1 ? 'investor' : 'investors'}',
                        style: const TextStyle(
                          color: Color(0xFF718078),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (visible.isEmpty)
                      const SizedBox(
                        height: 260,
                        child: EmptyView(
                          icon: Icons.pie_chart_outline,
                          message: 'No investors found.',
                        ),
                      ),
                    for (final investor in visible) _investorTile(investor),
                  ],
                ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: FilledButton.icon(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Add investor'),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color background,
    Color color,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: background,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF718078),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _investorTile(Map<String, dynamic> investor) {
    final active = investor['status'] == 'active';
    final name = '${investor['name'] ?? ''}'.trim();
    final ownership = (num.tryParse('${investor['ownership_percentage']}') ?? 0)
        .toStringAsFixed(2);
    final capital = moneyFormat.format(
      num.tryParse('${investor['capital_balance']}') ?? 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFFE5ECE8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => open(investor),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF5E7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    name.isEmpty ? 'I' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF07883F),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? 'Investor' : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF173B2A),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFDFF5E7)
                                  : const Color(0xFFFFE7E5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              active ? 'active' : 'inactive',
                              style: TextStyle(
                                color: active
                                    ? const Color(0xFF07883F)
                                    : const Color(0xFFD9443A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${investor['current_shares'] ?? 0} shares  •  $ownership% ownership',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718078),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Capital $capital',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173B2A),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  icon: const Icon(Icons.more_vert, color: Color(0xFF809087)),
                  onSelected: (value) {
                    if (value == 'view') open(investor);
                    if (value == 'edit') edit(investor);
                    if (value == 'delete') remove(investor);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.receipt_long_outlined),
                        title: Text('View ledger'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD9443A),
                        ),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: Color(0xFFA6B1AB),
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InvestorDetailScreen extends StatefulWidget {
  const InvestorDetailScreen({
    super.key,
    required this.api,
    required this.investorId,
    required this.investorName,
  });

  final ApiClient api;
  final int investorId;
  final String investorName;

  @override
  State<InvestorDetailScreen> createState() => _InvestorDetailScreenState();
}

class _InvestorDetailScreenState extends State<InvestorDetailScreen> {
  Map<String, dynamic> investor = {};
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> accounts = [];
  bool loading = true;

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final response = await widget.api.get('investors/${widget.investorId}');
      investor = widget.api.objectFrom(response);
      transactions = widget.api.listFrom(
        response is Map ? response['transactions'] : null,
      );
      accounts = widget.api.listFrom(
        response is Map ? response['accounts'] : null,
      );
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> editTransaction([Map<String, dynamic>? transaction]) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: transaction == null
          ? 'Post investor transaction'
          : 'Edit transaction',
      child: InvestorTransactionForm(
        api: widget.api,
        investorId: widget.investorId,
        accounts: accounts,
        initial: transaction,
      ),
    );
    if (saved == true) load();
  }

  Future<void> deleteTransaction(Map<String, dynamic> transaction) async {
    final confirmed = await confirmAction(
      context,
      'Delete transaction',
      'Cash, capital and share balances will be reversed.',
    );
    if (!confirmed) return;
    try {
      await widget.api.delete('investor-transactions/${transaction['id']}');
      if (mounted) showMessage(context, 'Transaction deleted and reversed.');
      load();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F8FB),
    appBar: AppBar(title: const Text('Investor details')),
    floatingActionButton: loading
        ? null
        : FloatingActionButton.extended(
            onPressed: editTransaction,
            icon: const Icon(Icons.add),
            label: const Text('Transaction'),
          ),
    body: loading
        ? const LoadingView()
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              children: [
                _investorHero(),
                const SizedBox(height: 14),
                _metricGrid(),
                const SizedBox(height: 18),
                _sectionTitle('Contact information'),
                _contactCard(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _sectionTitle('Transaction ledger')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF5E7),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${transactions.length} entries',
                        style: const TextStyle(
                          color: Color(0xFF07883F),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (transactions.isEmpty)
                  const SizedBox(
                    height: 260,
                    child: EmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'No investor transactions yet.',
                    ),
                  ),
                for (final transaction in transactions)
                  _transactionTile(transaction),
              ],
            ),
          ),
  );

  Widget _investorHero() {
    final name = '${investor['name'] ?? widget.investorName}'.trim();
    final active = investor['status'] == 'active';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF076F37), Color(0xFF2FA65C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24036D31),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
            ),
            child: Text(
              name.isEmpty ? 'I' : name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FARM INVESTOR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? 'Investor' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    active ? 'Active investor' : 'Inactive investor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.pie_chart_outline_rounded,
            color: Color(0x99FFFFFF),
            size: 34,
          ),
        ],
      ),
    );
  }

  Widget _metricGrid() {
    final metrics = [
      (
        'Shares',
        '${investor['current_shares'] ?? 0}',
        Icons.pie_chart_outline,
        const Color(0xFFE6F1FF),
        const Color(0xFF2775D8),
      ),
      (
        'Ownership',
        '${(num.tryParse('${investor['ownership_percentage']}') ?? 0).toStringAsFixed(2)}%',
        Icons.percent_rounded,
        const Color(0xFFFFF0D7),
        const Color(0xFFD9820B),
      ),
      (
        'Capital',
        moneyFormat.format(num.tryParse('${investor['capital_balance']}') ?? 0),
        Icons.account_balance_wallet_outlined,
        const Color(0xFFDFF5E7),
        const Color(0xFF07883F),
      ),
      (
        'Profit received',
        moneyFormat.format(
          num.tryParse('${investor['profit_distributed']}') ?? 0,
        ),
        Icons.payments_outlined,
        const Color(0xFFF0E5FF),
        const Color(0xFF8946D8),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 9) / 2;
        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 92),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5ECE8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: metric.$4,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(metric.$3, color: metric.$5, size: 17),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              metric.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF718078),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        metric.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173B2A),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF07883F),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF173B2A),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _contactCard() {
    final values = [
      (Icons.phone_outlined, 'Phone', investor['phone']),
      (Icons.email_outlined, 'Email', investor['email']),
      (Icons.badge_outlined, 'NID', investor['nid']),
      (Icons.location_on_outlined, 'Address', investor['address']),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5ECE8)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < values.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  values[index].$1,
                  color: const Color(0xFF07883F),
                  size: 20,
                ),
                const SizedBox(width: 11),
                SizedBox(
                  width: 62,
                  child: Text(
                    values[index].$2,
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${values[index].$3 ?? ''}'.trim().isEmpty
                        ? 'Not set'
                        : '${values[index].$3}',
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
          ],
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> transaction) {
    final contribution = transaction['type'] == 'capital_contribution';
    final type = '${transaction['type']}'.replaceAll('_', ' ');
    final amount = moneyFormat.format(
      num.tryParse('${transaction['amount']}') ?? 0,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5ECE8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => editTransaction(transaction),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: contribution
                      ? const Color(0xFFDFF5E7)
                      : const Color(0xFFFFE7E5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  contribution ? Icons.south_west : Icons.north_east,
                  color: contribution
                      ? const Color(0xFF07883F)
                      : const Color(0xFFD9443A),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF173B2A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatAppDate(transaction['transaction_date'])} · ${transaction['account']?['name'] ?? 'Account'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 11,
                      ),
                    ),
                    if (transaction['type'] != 'profit_distribution') ...[
                      const SizedBox(height: 3),
                      Text(
                        '${transaction['share_units'] ?? 0} shares',
                        style: const TextStyle(
                          color: Color(0xFF718078),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 105),
                child: Text(
                  '${contribution ? '+' : '-'}$amount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: contribution
                        ? const Color(0xFF07883F)
                        : const Color(0xFFD9443A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) {
                  if (value == 'edit') editTransaction(transaction);
                  if (value == 'delete') deleteTransaction(transaction);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: Color(0xFFD9443A),
                      ),
                      title: Text('Delete & reverse'),
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
}

class InvestorTransactionForm extends StatefulWidget {
  const InvestorTransactionForm({
    super.key,
    required this.api,
    required this.investorId,
    required this.accounts,
    this.initial,
  });

  final ApiClient api;
  final int investorId;
  final List<Map<String, dynamic>> accounts;
  final Map<String, dynamic>? initial;

  @override
  State<InvestorTransactionForm> createState() =>
      _InvestorTransactionFormState();
}

class _InvestorTransactionFormState extends State<InvestorTransactionForm> {
  final key = GlobalKey<FormState>();
  late final TextEditingController amount;
  late final TextEditingController shares;
  late final TextEditingController reference;
  late final TextEditingController notes;
  late String type;
  late DateTime date;
  int? accountId;
  bool saving = false;

  bool get editing => widget.initial?['id'] != null;
  bool get usesShares => type != 'profit_distribution';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    type = '${initial?['type'] ?? 'capital_contribution'}';
    accountId = initial?['financial_account_id'] as int?;
    amount = TextEditingController(text: initial?['amount']?.toString() ?? '');
    shares = TextEditingController(
      text: initial?['share_units']?.toString() ?? '',
    );
    reference = TextEditingController(
      text: initial?['reference']?.toString() ?? '',
    );
    notes = TextEditingController(text: initial?['notes']?.toString() ?? '');
    date =
        DateTime.tryParse('${initial?['transaction_date'] ?? ''}') ??
        DateTime.now();
  }

  @override
  void dispose() {
    amount.dispose();
    shares.dispose();
    reference.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    final payload = {
      'investor_id': widget.investorId,
      'financial_account_id': accountId,
      'type': type,
      'amount': num.tryParse(amount.text),
      'share_units': usesShares ? num.tryParse(shares.text) : 0,
      'transaction_date': dateFormat.format(date),
      'reference': reference.text.trim(),
      'notes': notes.text.trim(),
    };
    try {
      if (editing) {
        await widget.api.put(
          'investor-transactions/${widget.initial!['id']}',
          payload,
        );
      } else {
        await widget.api.post('investor-transactions', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: key,
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: InputDecoration(
            labelText: formFieldLabel('Transaction type', required: true),
          ),
          items:
              const {
                    'capital_contribution': 'Capital contribution',
                    'capital_withdrawal': 'Capital withdrawal',
                    'profit_distribution': 'Profit distribution',
                  }.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
          onChanged: (value) => setState(() => type = value ?? type),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: formFieldLabel('Amount (BDT)', required: true),
          ),
          validator: (value) => (num.tryParse(value ?? '') ?? 0) <= 0
              ? 'Enter an amount greater than zero'
              : null,
        ),
        if (usesShares) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: shares,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: formFieldLabel('Share units', required: true),
            ),
            validator: (value) => (num.tryParse(value ?? '') ?? 0) <= 0
                ? 'Enter share units greater than zero'
                : null,
          ),
        ],
        const SizedBox(height: 12),
        SearchableDropdown(
          label: 'Cash / bank account',
          items: widget.accounts,
          value: accountId,
          required: true,
          labelBuilder: (item) =>
              '${item['name']} · ${moneyFormat.format(num.tryParse('${item['current_balance']}') ?? 0)}',
          onChanged: (value) => accountId = value,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(formFieldLabel('Transaction date', required: true)),
          subtitle: Text(displayDateFormat.format(date)),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => date = picked);
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: reference,
          decoration: const InputDecoration(labelText: 'Reference'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(editing ? 'Update & recalculate' : 'Post transaction'),
          ),
        ),
      ],
    ),
  );
}
