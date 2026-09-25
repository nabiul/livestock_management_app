import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';
import 'generic/resource_screen.dart';
import 'trade_screen.dart';

class LivestockDetailScreen extends StatefulWidget {
  const LivestockDetailScreen({
    super.key,
    required this.api,
    required this.recordId,
    required this.isBatch,
  });

  final ApiClient api;
  final int recordId;
  final bool isBatch;

  @override
  State<LivestockDetailScreen> createState() => _LivestockDetailScreenState();
}

class _LivestockDetailScreenState extends State<LivestockDetailScreen> {
  Map<String, dynamic>? record;
  bool loading = true;
  String? error;

  String get endpoint => widget.isBatch
      ? 'livestock-batches/${widget.recordId}'
      : 'animals/${widget.recordId}';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      record = widget.api.objectFrom(await widget.api.get(endpoint));
    } catch (exception) {
      error = errorMessage(exception);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBatch ? 'Batch details' : 'Livestock details';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: loading
          ? const LoadingView()
          : error != null
          ? _ErrorView(message: error!, onRetry: load)
          : _buildDetails(record ?? const {}),
    );
  }

  Widget _buildDetails(Map<String, dynamic> data) {
    final access = _map(data['access']);
    final tabs = <_DetailsTab>[
      _DetailsTab(
        label: 'Overview',
        icon: Icons.dashboard_outlined,
        child: _overview(data),
      ),
      if (widget.isBatch)
        _DetailsTab(
          label: 'Stock history',
          icon: Icons.swap_vert_circle_outlined,
          child: _stockHistory(data),
        ),
      if (!widget.isBatch && access['health'] == true)
        _DetailsTab(
          label: 'Health',
          icon: Icons.health_and_safety_outlined,
          child: _health(data),
        ),
      if (access['production'] == true)
        _DetailsTab(
          label: 'Production',
          icon: Icons.agriculture_outlined,
          child: _production(data),
        ),
      if (access['accounting'] == true)
        _DetailsTab(
          label: 'Finance',
          icon: Icons.account_balance_wallet_outlined,
          child: _finance(data),
        ),
      if (access['sales'] == true || access['purchases'] == true)
        _DetailsTab(
          label: 'Trade',
          icon: Icons.receipt_long_outlined,
          child: _trade(data, access),
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          _Header(data: data, isBatch: widget.isBatch),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final tab in tabs)
                  Tab(icon: Icon(tab.icon, size: 20), text: tab.label),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [for (final tab in tabs) tab.child]),
          ),
        ],
      ),
    );
  }

  Widget _overview(Map<String, dynamic> data) {
    final values = widget.isBatch
        ? <_InfoValue>[
            _InfoValue('Batch code', data['batch_code']),
            _InfoValue('Farm', _map(data['farm'])['name']),
            _InfoValue('Species', _map(data['species'])['name']),
            _InfoValue('Breed', data['breed']),
            _InfoValue(
              'Received on',
              formatAppDate(data['received_on'], fallback: 'Not set'),
            ),
            _InfoValue('Status', _label(data['status'])),
            _InfoValue(
              'Initial livestock',
              '${_display(data['initial_quantity'])} head',
            ),
            _InfoValue(
              'Available livestock',
              '${_display(data['current_quantity'])} head',
            ),
            _InfoValue('Average unit cost', _money(data['average_unit_cost'])),
            _InfoValue(
              'Current stock value',
              _money(
                _number(data['current_quantity']) *
                    _number(data['average_unit_cost']),
              ),
            ),
            _InfoValue(
              'Purchase invoice',
              _map(data['purchase'])['invoice_number'],
            ),
            _InfoValue(
              'Created',
              formatAppDate(data['created_at'], fallback: 'Not set'),
            ),
            _InfoValue(
              'Last updated',
              formatAppDate(data['updated_at'], fallback: 'Not set'),
            ),
          ]
        : <_InfoValue>[
            _InfoValue('Tag number', data['tag_number']),
            _InfoValue('Name', data['name']),
            _InfoValue('Farm', _map(data['farm'])['name']),
            _InfoValue('Species', _map(data['species'])['name']),
            _InfoValue('Breed', data['breed']),
            _InfoValue('Sex', _label(data['sex'])),
            _InfoValue(
              'Date of birth',
              formatAppDate(data['date_of_birth'], fallback: 'Not set'),
            ),
            _InfoValue('Status', _label(data['status'])),
            _InfoValue(
              'Created',
              formatAppDate(data['created_at'], fallback: 'Not set'),
            ),
            _InfoValue(
              'Last updated',
              formatAppDate(data['updated_at'], fallback: 'Not set'),
            ),
          ];
    final notes = data['notes']?.toString().trim();

    return _TabList(
      onRefresh: load,
      children: [
        const _SectionTitle('General information'),
        _InfoGrid(values: values),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionTitle('Notes'),
          _NoteCard(notes),
        ],
      ],
    );
  }

  Widget _stockHistory(Map<String, dynamic> data) {
    final rows = _maps(data['transactions']);
    return _recordsTab(
      rows,
      emptyIcon: Icons.swap_vert_circle_outlined,
      emptyMessage: 'No stock movement recorded for this batch.',
      builder: (row) {
        final direction = '${row['direction'] ?? ''}'.toLowerCase();
        return _RecordCard(
          icon: direction == 'in' ? Icons.south_west : Icons.north_east,
          title: '${_label(row['type'])} · ${_display(row['quantity'])} head',
          subtitle: _join([
            formatAppDate(row['occurred_on']),
            row['reference_type'],
            row['reference_id'] == null ? null : '#${row['reference_id']}',
          ]),
          badge: direction,
          details: _join([row['notes']]),
        );
      },
    );
  }

  Widget _health(Map<String, dynamic> data) {
    final rows = _maps(data['health_records']);
    return _recordsTab(
      rows,
      emptyIcon: Icons.health_and_safety_outlined,
      emptyMessage: 'No health record found for this livestock.',
      createLabel: 'Add health record',
      onCreate: () => _createHealth(data),
      builder: (row) => _RecordCard(
        icon: Icons.medical_services_outlined,
        title: _display(row['title'], fallback: _label(row['type'])),
        subtitle: _join([
          _label(row['type']),
          formatAppDate(row['observed_on']),
          row['next_due_date'] == null
              ? null
              : 'Next: ${formatAppDate(row['next_due_date'])}',
        ]),
        badge: row['cost'] == null ? null : _money(row['cost']),
        details: _join([
          row['treatment'] == null ? null : 'Treatment: ${row['treatment']}',
          row['medicine'] == null ? null : 'Medicine: ${row['medicine']}',
          row['notes'],
        ], separator: '\n'),
      ),
    );
  }

  Widget _production(Map<String, dynamic> data) {
    final rows = widget.isBatch
        ? [
            ..._maps(
              data['productions_as_source'],
            ).map((row) => {...row, '_relation': 'Produced by batch'}),
            ..._maps(
              data['productions_as_destination'],
            ).map((row) => {...row, '_relation': 'Added to batch'}),
          ]
        : _maps(data['production_records']);
    rows.sort(
      (a, b) =>
          '${b['recorded_on'] ?? ''}'.compareTo('${a['recorded_on'] ?? ''}'),
    );
    return _recordsTab(
      rows,
      emptyIcon: Icons.agriculture_outlined,
      emptyMessage: 'No production record found.',
      createLabel: 'Add production',
      onCreate: () => _createProduction(data),
      builder: (row) {
        final item = _map(row['inventory_item']);
        final batch = _map(row['livestock_batch']);
        final offspring = _map(row['offspring_animal']);
        return _RecordCard(
          icon: row['type'] == 'birth'
              ? Icons.pets_outlined
              : Icons.inventory_2_outlined,
          title:
              '${_label(row['type'])} · ${_display(row['quantity'])} ${_display(row['unit'], fallback: '')}',
          subtitle: _join([
            formatAppDate(row['recorded_on']),
            row['_relation'],
            item['name'],
            batch['batch_code'],
            offspring['tag_number'] == null
                ? null
                : 'Newborn: ${offspring['tag_number']}',
          ]),
          badge: _number(row['unit_price']) > 0
              ? _money(_number(row['quantity']) * _number(row['unit_price']))
              : null,
          details: _join([
            row['quality_grade'] == null
                ? null
                : 'Quality: ${row['quality_grade']}',
            row['notes'],
          ], separator: '\n'),
        );
      },
    );
  }

  Widget _finance(Map<String, dynamic> data) {
    final rows = _maps(data['financial_transactions']);
    return _recordsTab(
      rows,
      emptyIcon: Icons.account_balance_wallet_outlined,
      emptyMessage: 'No income or expense found.',
      createLabel: 'Add income / expense',
      onCreate: () => _createFinance(data),
      builder: (row) {
        final category = _map(row['category_model']);
        final account = _map(row['account']);
        return _RecordCard(
          icon: row['type'] == 'income'
              ? Icons.trending_up
              : Icons.trending_down,
          title: _display(category['name'], fallback: _label(row['category'])),
          subtitle: _join([
            formatAppDate(row['transaction_date']),
            account['name'],
            _label(row['payment_method']),
            row['reference'],
          ]),
          badge: _money(row['amount']),
          details: _join([row['notes']]),
        );
      },
    );
  }

  Widget _trade(Map<String, dynamic> data, Map<String, dynamic> access) {
    final sales = access['sales'] == true
        ? _maps(data['sale_items'])
        : <Map<String, dynamic>>[];
    final purchases = access['purchases'] == true
        ? _maps(data['purchase_items'])
        : <Map<String, dynamic>>[];
    if (sales.isEmpty && purchases.isEmpty) {
      return _recordsTab(
        const [],
        emptyIcon: Icons.receipt_long_outlined,
        emptyMessage: 'No sale or purchase found.',
        builder: (_) => const SizedBox.shrink(),
      );
    }
    return _TabList(
      onRefresh: load,
      children: [
        if (access['sales'] == true &&
            (widget.isBatch
                ? _number(data['current_quantity']) > 0
                : data['status'] == 'active')) ...[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _createSale(data),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Create sale'),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (access['sales'] == true) ...[
          _SectionTitle('Sales (${sales.length})'),
          if (sales.isEmpty)
            const _InlineEmpty('No sale found.')
          else
            ...sales.map((row) => _tradeCard(row, sale: true)),
        ],
        if (access['sales'] == true && access['purchases'] == true)
          const SizedBox(height: 20),
        if (access['purchases'] == true) ...[
          _SectionTitle('Purchases (${purchases.length})'),
          if (purchases.isEmpty)
            const _InlineEmpty('No purchase found.')
          else
            ...purchases.map((row) => _tradeCard(row, sale: false)),
        ],
      ],
    );
  }

  Widget _tradeCard(Map<String, dynamic> row, {required bool sale}) {
    final invoice = _map(row[sale ? 'sale' : 'purchase']);
    final party = _map(invoice[sale ? 'customer' : 'vendor']);
    return _RecordCard(
      icon: sale ? Icons.point_of_sale_outlined : Icons.shopping_cart_outlined,
      title: _display(
        invoice['invoice_number'],
        fallback: sale ? 'Sale' : 'Purchase',
      ),
      subtitle: _join([
        formatAppDate(invoice[sale ? 'sale_date' : 'purchase_date']),
        party['name'],
        '${_display(row['quantity'])} ${_display(row['unit'], fallback: '')}',
        row['livestock_head_count'] == null
            ? null
            : '${row['livestock_head_count']} head',
      ]),
      badge: _money(row['line_total']),
      details: _join([
        row['description'],
        invoice['status'] == null
            ? null
            : 'Status: ${_label(invoice['status'])}',
      ], separator: '\n'),
    );
  }

  Widget _recordsTab(
    List<Map<String, dynamic>> rows, {
    required IconData emptyIcon,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) builder,
    String? createLabel,
    Future<void> Function()? onCreate,
  }) {
    final records = RefreshIndicator(
      onRefresh: load,
      child: rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * .2),
                EmptyView(icon: emptyIcon, message: emptyMessage),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              itemCount: rows.length,
              itemBuilder: (_, index) => builder(rows[index]),
            ),
    );
    if (onCreate == null || createLabel == null) return records;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(createLabel),
            ),
          ),
        ),
        Expanded(child: records),
      ],
    );
  }

  Future<void> _createHealth(Map<String, dynamic> data) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: 'Add health record · ${data['tag_number']}',
      child: ResourceForm(
        api: widget.api,
        endpoint: 'animals/${widget.recordId}/health-records',
        fields: const [
          FieldSpec(
            'type',
            'Type',
            type: FieldType.select,
            options: [
              'vaccination',
              'treatment',
              'checkup',
              'deworming',
              'surgery',
            ],
            required: true,
          ),
          FieldSpec('title', 'Title', required: true),
          FieldSpec(
            'observed_on',
            'Date',
            type: FieldType.date,
            required: true,
          ),
          FieldSpec('treatment', 'Treatment'),
          FieldSpec('medicine', 'Medicine'),
          FieldSpec('cost', 'Cost', type: FieldType.number),
          FieldSpec('next_due_date', 'Next due date', type: FieldType.date),
          FieldSpec('notes', 'Notes', type: FieldType.multiline),
        ],
        initial: {'observed_on': dateFormat.format(DateTime.now())},
      ),
    );
    if (saved == true) load();
  }

  Future<void> _createProduction(Map<String, dynamic> data) async {
    final saved = await AppSheet.show<bool>(
      context,
      title:
          'Add production · ${widget.isBatch ? data['batch_code'] : data['tag_number']}',
      child: ResourceForm(
        api: widget.api,
        endpoint: 'production-records',
        fields: _productionFields,
        initial: {
          'farm_id': data['farm_id'],
          'source_type': widget.isBatch ? 'batch' : 'individual',
          if (widget.isBatch)
            'source_livestock_batch_id': widget.recordId
          else
            'animal_id': widget.recordId,
          'recorded_on': dateFormat.format(DateTime.now()),
        },
      ),
    );
    if (saved == true) load();
  }

  Future<void> _createFinance(Map<String, dynamic> data) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: 'Add income / expense',
      child: ResourceForm(
        api: widget.api,
        endpoint: 'financial-transactions',
        fields: _financeFields,
        initial: {
          'farm_id': data['farm_id'],
          if (widget.isBatch)
            'livestock_batch_id': widget.recordId
          else
            'animal_id': widget.recordId,
          'type': 'expense',
          'transaction_date': dateFormat.format(DateTime.now()),
          'vat_amount': 0,
          'tax_amount': 0,
        },
      ),
    );
    if (saved == true) load();
  }

  Future<void> _createSale(Map<String, dynamic> data) async {
    final saved = await AppSheet.show<bool>(
      context,
      title:
          'Create sale · ${widget.isBatch ? data['batch_code'] : data['tag_number']}',
      child: TradeForm(
        api: widget.api,
        isSale: true,
        initialItemType: widget.isBatch ? 'livestock_batch' : 'livestock',
        initialReferenceId: widget.recordId,
        initialFarmId: data['farm_id'] as int?,
      ),
    );
    if (saved == true) load();
  }
}

const _productionFields = [
  FieldSpec(
    'farm_id',
    'Farm',
    type: FieldType.lookup,
    lookupPath: 'farms',
    required: true,
  ),
  FieldSpec(
    'source_type',
    'Production source',
    type: FieldType.select,
    options: ['individual', 'batch', 'farm'],
    required: true,
  ),
  FieldSpec(
    'animal_id',
    'Individual livestock',
    type: FieldType.lookup,
    lookupPath: 'animals',
    availableOnly: true,
    required: true,
    visibleWhenKey: 'source_type',
    visibleWhenValues: ['individual'],
  ),
  FieldSpec(
    'source_livestock_batch_id',
    'Producing batch',
    type: FieldType.lookup,
    lookupPath: 'livestock-batches',
    required: true,
    visibleWhenKey: 'source_type',
    visibleWhenValues: ['batch'],
  ),
  FieldSpec(
    'inventory_item_id',
    'Add product to inventory',
    type: FieldType.lookup,
    lookupPath: 'inventory-items',
    hiddenWhenKey: 'type',
    hiddenWhenValues: ['birth', 'hatch'],
  ),
  FieldSpec(
    'newborn_destination',
    'Newborn registration',
    type: FieldType.select,
    options: ['batch', 'individual'],
    defaultValue: 'batch',
    required: true,
    visibleWhenKey: 'type',
    visibleWhenValues: ['birth', 'hatch'],
  ),
  FieldSpec(
    'livestock_batch_id',
    'Newborn destination batch',
    type: FieldType.lookup,
    lookupPath: 'livestock-batches',
    required: true,
    visibleWhenKey: 'newborn_destination',
    visibleWhenValues: ['batch'],
    hiddenWhenKey: 'type',
    hiddenWhenValues: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'other',
    ],
  ),
  FieldSpec(
    'offspring_species_id',
    'Newborn species',
    type: FieldType.lookup,
    lookupPath: 'species',
    required: true,
    visibleWhenKey: 'newborn_destination',
    visibleWhenValues: ['individual'],
    hiddenWhenKey: 'type',
    hiddenWhenValues: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'other',
    ],
  ),
  FieldSpec(
    'offspring_tag_number',
    'Newborn tag number',
    required: true,
    visibleWhenKey: 'newborn_destination',
    visibleWhenValues: ['individual'],
    hiddenWhenKey: 'type',
    hiddenWhenValues: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'other',
    ],
  ),
  FieldSpec(
    'offspring_name',
    'Newborn name',
    visibleWhenKey: 'newborn_destination',
    visibleWhenValues: ['individual'],
    hiddenWhenKey: 'type',
    hiddenWhenValues: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'other',
    ],
  ),
  FieldSpec(
    'offspring_sex',
    'Newborn sex',
    type: FieldType.select,
    options: ['male', 'female'],
    visibleWhenKey: 'newborn_destination',
    visibleWhenValues: ['individual'],
    hiddenWhenKey: 'type',
    hiddenWhenValues: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'other',
    ],
  ),
  FieldSpec(
    'offspring_breed',
    'Newborn breed',
    visibleWhenKey: 'newborn_destination',
    visibleWhenValues: ['individual'],
    hiddenWhenKey: 'type',
    hiddenWhenValues: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'other',
    ],
  ),
  FieldSpec(
    'type',
    'Production type',
    type: FieldType.select,
    options: [
      'milk',
      'egg',
      'wool',
      'weight',
      'meat',
      'manure',
      'birth',
      'hatch',
      'other',
    ],
    required: true,
  ),
  FieldSpec('quantity', 'Quantity', type: FieldType.number, required: true),
  FieldSpec(
    'unit',
    'Unit',
    type: FieldType.select,
    options: ['litre', 'kg', 'gram', 'piece', 'dozen', 'head'],
    required: true,
  ),
  FieldSpec('recorded_on', 'Date', type: FieldType.date, required: true),
  FieldSpec('quality_grade', 'Quality grade'),
  FieldSpec('unit_price', 'Expected unit price', type: FieldType.number),
  FieldSpec('notes', 'Notes', type: FieldType.multiline),
];

const _financeFields = [
  FieldSpec('farm_id', 'Farm', type: FieldType.lookup, lookupPath: 'farms'),
  FieldSpec(
    'animal_id',
    'Individual livestock',
    type: FieldType.lookup,
    lookupPath: 'animals',
    availableOnly: true,
  ),
  FieldSpec(
    'livestock_batch_id',
    'Livestock batch',
    type: FieldType.lookup,
    lookupPath: 'livestock-batches',
  ),
  FieldSpec(
    'type',
    'Type',
    type: FieldType.select,
    options: ['income', 'expense'],
    required: true,
  ),
  FieldSpec(
    'financial_category_id',
    'Category',
    type: FieldType.lookup,
    lookupPath: 'financial-categories',
    required: true,
  ),
  FieldSpec(
    'financial_account_id',
    'Cash / bank account',
    type: FieldType.lookup,
    lookupPath: 'accounts',
    required: true,
  ),
  FieldSpec('amount', 'Amount', type: FieldType.number, required: true),
  FieldSpec('vat_amount', 'VAT amount', type: FieldType.number),
  FieldSpec('tax_amount', 'Tax amount', type: FieldType.number),
  FieldSpec('transaction_date', 'Date', type: FieldType.date, required: true),
  FieldSpec('reference', 'Reference'),
  FieldSpec('notes', 'Notes', type: FieldType.multiline),
];

class _Header extends StatelessWidget {
  const _Header({required this.data, required this.isBatch});

  final Map<String, dynamic> data;
  final bool isBatch;

  @override
  Widget build(BuildContext context) {
    final name = isBatch
        ? _display(data['batch_code'])
        : _join([data['tag_number'], data['name']], separator: ' · ');
    final species = _map(data['species']);
    final farm = _map(data['farm']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(
              isBatch ? Icons.groups_2_outlined : Icons.pets,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty
                      ? (isBatch ? 'Livestock batch' : 'Livestock')
                      : name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(_join([species['name'], data['breed'], farm['name']])),
              ],
            ),
          ),
          StatusChip(_display(data['status'], fallback: 'active')),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.values});
  final List<_InfoValue> values;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 3 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final value in values)
            SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _display(value.value),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.details,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final String? details;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Icon(icon, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (badge != null && badge!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (details != null && details!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(details!),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TabList extends StatelessWidget {
  const _TabList({required this.onRefresh, required this.children});
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: children,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Text(text),
  );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(child: Text(text)),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _DetailsTab {
  const _DetailsTab({
    required this.label,
    required this.icon,
    required this.child,
  });
  final String label;
  final IconData icon;
  final Widget child;
}

class _InfoValue {
  const _InfoValue(this.label, this.value);
  final String label;
  final dynamic value;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : <Map<String, dynamic>>[];

num _number(dynamic value) => num.tryParse('$value') ?? 0;

String _money(dynamic value) => moneyFormat.format(_number(value));

String _display(dynamic value, {String fallback = 'Not set'}) {
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

String _label(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  return text
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _join(List<dynamic> values, {String separator = ' · '}) => values
    .where((value) => value != null && value.toString().trim().isNotEmpty)
    .map((value) => value.toString().trim())
    .join(separator);
