import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key, required this.api, required this.isSale});

  final ApiClient api;
  final bool isSale;

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  String get _endpoint => widget.isSale ? 'sales' : 'purchases';
  String get _title => widget.isSale ? 'Sales' : 'Purchases';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = widget.api.listFrom(
        await widget.api.get(_endpoint, query: {'per_page': 100}),
      );
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final saved = await AppSheet.show<bool>(
      context,
      title: widget.isSale ? 'New sale' : 'New purchase',
      child: TradeForm(api: widget.api, isSale: widget.isSale),
    );
    if (saved == true) _load();
  }

  Future<void> _payment(Map<String, dynamic> trade) async {
    final due =
        (num.tryParse('${trade['total']}') ?? 0) -
        (num.tryParse('${trade['paid']}') ?? 0);
    final saved = await AppSheet.show<bool>(
      context,
      title: widget.isSale ? 'Receive invoice payment' : 'Pay invoice',
      child: InvoicePaymentForm(
        api: widget.api,
        endpoint: '$_endpoint/${trade['id']}/payments',
        due: due,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _cancel(Map<String, dynamic> trade) async {
    final confirmed = await confirmAction(
      context,
      'Cancel ${widget.isSale ? 'sale' : 'purchase'}',
      'Stock, cash/bank and party ledger effects will be reversed.',
    );
    if (!confirmed) return;
    try {
      await widget.api.delete('$_endpoint/${trade['id']}');
      if (mounted) showMessage(context, 'Transaction cancelled.');
      _load();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'POS invoices, payments and stock movement',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
          ),
          if (_items.isEmpty)
            SliverFillRemaining(
              child: EmptyView(
                icon: widget.isSale ? Icons.point_of_sale : Icons.shopping_cart,
                message: 'No $_title recorded yet.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
              sliver: SliverList.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final trade = _items[index];
                  final total = num.tryParse('${trade['total']}') ?? 0;
                  final paid = num.tryParse('${trade['paid']}') ?? 0;
                  final due = total - paid;
                  final party = widget.isSale
                      ? trade['customer']
                      : trade['vendor'];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              widget.isSale
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${trade['invoice_number']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${party?['name'] ?? 'Walk-in'} · '
                                  '${formatAppDate(trade[widget.isSale ? 'sale_date' : 'purchase_date'])}',
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    Text('Total ${moneyFormat.format(total)}'),
                                    Text(
                                      'Due ${moneyFormat.format(due)}',
                                      style: TextStyle(
                                        color: due > 0
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'payment') _payment(trade);
                              if (value == 'cancel') _cancel(trade);
                            },
                            itemBuilder: (_) => [
                              if (due > 0)
                                PopupMenuItem(
                                  value: 'payment',
                                  child: Text(
                                    widget.isSale
                                        ? 'Receive payment'
                                        : 'Make payment',
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancel invoice'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class TradeForm extends StatefulWidget {
  const TradeForm({
    super.key,
    required this.api,
    required this.isSale,
    this.initialItemType,
    this.initialReferenceId,
    this.initialFarmId,
  });

  final ApiClient api;
  final bool isSale;
  final String? initialItemType;
  final int? initialReferenceId;
  final int? initialFarmId;

  @override
  State<TradeForm> createState() => _TradeFormState();
}

class _TradeFormState extends State<TradeForm> {
  final _formKey = GlobalKey<FormState>();
  final _discount = TextEditingController(text: '0');
  final _paid = TextEditingController(text: '0');
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  final List<_TradeLine> _lines = [_TradeLine()];
  List<Map<String, dynamic>> farms = [];
  List<Map<String, dynamic>> parties = [];
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> inventory = [];
  List<Map<String, dynamic>> animals = [];
  List<Map<String, dynamic>> batches = [];
  List<Map<String, dynamic>> species = [];
  int? farmId;
  int? partyId;
  int? accountId;
  DateTime date = DateTime.now();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final responses = await Future.wait([
        widget.api.get('farms', query: {'per_page': 100}),
        widget.api.get('contacts', query: {'per_page': 100}),
        widget.api.get('accounts', query: {'per_page': 100}),
        widget.api.get('inventory-items', query: {'per_page': 100}),
        widget.api.get(
          'animals',
          query: {'per_page': 100, if (widget.isSale) 'available': 1},
        ),
        widget.api.get(
          'livestock-batches',
          query: {'per_page': 100, if (widget.isSale) 'available': 1},
        ),
        widget.api.get('species'),
      ]);
      farms = widget.api.listFrom(responses[0]);
      final allParties = widget.api.listFrom(responses[1]);
      parties = allParties.where((item) {
        final type = item['type'];
        return type == 'both' ||
            type == (widget.isSale ? 'customer' : 'vendor');
      }).toList();
      accounts = widget.api.listFrom(responses[2]);
      inventory = widget.api.listFrom(responses[3]);
      animals = widget.api.listFrom(responses[4]);
      batches = widget.api.listFrom(responses[5]);
      species = widget.api.listFrom(responses[6]);
      farmId =
          widget.initialFarmId ??
          (farms.isEmpty ? null : farms.first['id'] as int?);
      accountId = accounts.isEmpty ? null : accounts.first['id'] as int?;
      if (widget.isSale &&
          widget.initialItemType != null &&
          widget.initialReferenceId != null) {
        final line = _lines.first;
        line.type = widget.initialItemType!;
        line.referenceId = widget.initialReferenceId;
        line.unit = 'head';
        line.quantity.text = '1';
        line.headCount.text = '1';
        final choices = line.type == 'livestock' ? animals : batches;
        final selected = choices
            .where((item) => item['id'] == line.referenceId)
            .firstOrNull;
        line.description.text = line.type == 'livestock'
            ? 'Animal ${selected?['tag_number'] ?? ''}'
            : 'Batch ${selected?['batch_code'] ?? ''}';
      }
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  num get subtotal => _lines.fold<num>(0, (sum, line) {
    final quantity = num.tryParse(line.quantity.text) ?? 0;
    final price = num.tryParse(line.price.text) ?? 0;
    return sum + quantity * price;
  });

  num get total => subtotal - (num.tryParse(_discount.text) ?? 0);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.api.post(widget.isSale ? 'sales' : 'purchases', {
        'farm_id': farmId,
        widget.isSale ? 'customer_id' : 'vendor_id': partyId,
        'financial_account_id': accountId,
        widget.isSale ? 'sale_date' : 'purchase_date': dateFormat.format(date),
        if (!widget.isSale) 'vendor_invoice': _reference.text.trim(),
        'discount': num.tryParse(_discount.text) ?? 0,
        'paid': num.tryParse(_paid.text) ?? 0,
        'notes': _notes.text.trim(),
        'items': _lines.map((line) {
          final map = <String, dynamic>{
            'item_type': line.type,
            'reference_id': line.referenceId,
            'description': line.description.text.trim(),
            'quantity': num.tryParse(line.quantity.text),
            'unit': line.unit,
            widget.isSale ? 'unit_price' : 'unit_cost': num.tryParse(
              line.price.text,
            ),
          };
          if (line.type == 'livestock_batch') {
            map['livestock_head_count'] = int.tryParse(line.headCount.text);
            if (!widget.isSale) {
              map['species_id'] = line.speciesId;
              map['batch_code'] = line.batchCode.text.trim();
              map['breed'] = line.breed.text.trim();
            }
          }
          if (line.type == 'livestock' && !widget.isSale) {
            map['species_id'] = line.speciesId;
            map['tag_number'] = line.tagNumber.text.trim();
            map['name'] = line.animalName.text.trim();
            map['sex'] = line.sex;
            map['breed'] = line.breed.text.trim();
            map['date_of_birth'] = line.dateOfBirth.text.trim().isEmpty
                ? null
                : line.dateOfBirth.text.trim();
          }
          return map;
        }).toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    _discount.dispose();
    _paid.dispose();
    _reference.dispose();
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox(height: 300, child: LoadingView());
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchableDropdown(
            label: 'Farm',
            items: farms,
            value: farmId,
            required: true,
            onChanged: (value) => setState(() => farmId = value),
          ),
          const SizedBox(height: 12),
          SearchableDropdown(
            label: widget.isSale ? 'Customer' : 'Vendor',
            items: parties,
            value: partyId,
            onChanged: (value) => setState(() => partyId = value),
          ),
          const SizedBox(height: 12),
          SearchableDropdown(
            label: 'Cash / bank account',
            items: accounts,
            value: accountId,
            required: true,
            onChanged: (value) => setState(() => accountId = value),
          ),
          const SizedBox(height: 12),
          _dateField(),
          if (!widget.isSale) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _reference,
              decoration: const InputDecoration(labelText: 'Vendor invoice'),
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Invoice items'),
          for (var i = 0; i < _lines.length; i++) _lineCard(i, _lines[i]),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _lines.add(_TradeLine())),
              icon: const Icon(Icons.add),
              label: const Text('Add line'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _numberField(_discount, 'Discount')),
              const SizedBox(width: 10),
              Expanded(child: _numberField(_paid, 'Paid now')),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invoice total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    moneyFormat.format(total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                widget.isSale ? 'Complete sale' : 'Complete purchase',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField() => InkWell(
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (selected != null) setState(() => date = selected);
    },
    child: InputDecorator(
      decoration: const InputDecoration(labelText: 'Date'),
      child: Text(displayDateFormat.format(date)),
    ),
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => setState(() {}),
    validator: required
        ? (value) => (num.tryParse(value ?? '') ?? 0) <= 0
              ? '$label is required'
              : null
        : null,
  );

  Widget _wholeNumberField(
    TextEditingController controller,
    String label, {
    int? maximum,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      helperText: maximum == null ? null : '$maximum head available',
    ),
    onChanged: (_) => setState(() {}),
    validator: (value) {
      final number = num.tryParse(value ?? '');
      if (number == null || number < 1 || number != number.roundToDouble()) {
        return 'Enter a whole number';
      }
      if (maximum != null && number > maximum) {
        return 'Only $maximum available';
      }
      return null;
    },
  );

  Widget _lineCard(int index, _TradeLine line) {
    final types = widget.isSale
        ? ['inventory', 'livestock', 'livestock_batch', 'other']
        : ['inventory', 'livestock', 'livestock_batch', 'other'];
    final selectedBatch = batches
        .where((item) => item['id'] == line.referenceId)
        .firstOrNull;
    final availableHeads = int.tryParse(
      '${selectedBatch?['current_quantity'] ?? ''}',
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.type,
                    decoration: const InputDecoration(labelText: 'Item type'),
                    items: types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      line.type = value ?? 'inventory';
                      line.referenceId = null;
                      if (line.type == 'livestock') {
                        line.unit = 'head';
                        line.quantity.text = '1';
                        if (!widget.isSale) {
                          line.description.text = 'Individual livestock';
                        }
                      }
                      if (line.type == 'livestock_batch') {
                        line.unit = 'head';
                        line.quantity.text = '1';
                        line.headCount.text = '1';
                      }
                    }),
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      _lines.removeAt(index).dispose();
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (line.type == 'inventory')
              SearchableDropdown(
                label: 'Inventory item',
                items: inventory,
                value: line.referenceId,
                required: true,
                onChanged: (value) => setState(() {
                  line.referenceId = value;
                  final item = inventory
                      .where((e) => e['id'] == value)
                      .firstOrNull;
                  line.description.text = item?['name']?.toString() ?? '';
                  line.unit = item?['unit']?.toString() ?? 'kg';
                }),
              ),
            if (line.type == 'livestock' && widget.isSale)
              SearchableDropdown(
                label: 'Animal',
                items: animals
                    .map(
                      (item) => {
                        ...item,
                        'label': '${item['tag_number']} ${item['name'] ?? ''}',
                      },
                    )
                    .toList(),
                value: line.referenceId,
                required: true,
                onChanged: (value) => setState(() {
                  line.referenceId = value;
                  final item = animals
                      .where((e) => e['id'] == value)
                      .firstOrNull;
                  line.description.text = 'Animal ${item?['tag_number'] ?? ''}';
                }),
              ),
            if (line.type == 'livestock' && !widget.isSale) ...[
              SearchableDropdown(
                label: 'Species',
                items: species,
                value: line.speciesId,
                required: true,
                onChanged: (value) => line.speciesId = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: line.tagNumber,
                decoration: const InputDecoration(labelText: 'Tag number'),
                validator: _required,
                onChanged: (value) => line.description.text = value.isEmpty
                    ? 'Individual livestock'
                    : 'Individual livestock · $value',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: line.animalName,
                      decoration: const InputDecoration(
                        labelText: 'Animal name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: line.sex,
                      decoration: const InputDecoration(labelText: 'Sex'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Not specified'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (value) => line.sex = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: line.breed,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(line.dateOfBirth.text) ??
                              DateTime.now(),
                          firstDate: DateTime(1990),
                          lastDate: DateTime.now(),
                        );
                        if (selected != null) {
                          setState(() {
                            line.dateOfBirth.text = dateFormat.format(selected);
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                          suffixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        child: Text(
                          line.dateOfBirth.text.isEmpty
                              ? 'Select date'
                              : formatAppDate(line.dateOfBirth.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (line.type == 'livestock_batch' && widget.isSale)
              SearchableDropdown(
                label: 'Livestock batch',
                items: batches
                    .map(
                      (item) => {
                        ...item,
                        'label':
                            '${item['batch_code']} · ${item['current_quantity']} head',
                      },
                    )
                    .toList(),
                value: line.referenceId,
                required: true,
                onChanged: (value) => setState(() {
                  line.referenceId = value;
                  final item = batches
                      .where((e) => e['id'] == value)
                      .firstOrNull;
                  line.description.text = 'Batch ${item?['batch_code'] ?? ''}';
                }),
              ),
            if (line.type == 'livestock_batch' && !widget.isSale) ...[
              SearchableDropdown(
                label: 'Species',
                items: species,
                value: line.speciesId,
                required: true,
                onChanged: (value) => line.speciesId = value,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: line.batchCode,
                      decoration: const InputDecoration(
                        labelText: 'Batch code',
                      ),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: line.breed,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              controller: line.description,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            if (widget.isSale &&
                (line.type == 'livestock' ||
                    line.type == 'livestock_batch')) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('sale-basis-${line.type}-${line.unit}'),
                initialValue: line.unit,
                decoration: const InputDecoration(labelText: 'Sell by'),
                items: const [
                  DropdownMenuItem(value: 'head', child: Text('Piece / head')),
                  DropdownMenuItem(
                    value: 'kg',
                    child: Text('Live weight (kg)'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  line.unit = value ?? 'head';
                  line.quantity.text = line.unit == 'head' ? '1' : '';
                  line.headCount.text = '1';
                }),
              ),
              const SizedBox(height: 10),
              if (line.type == 'livestock' && line.unit == 'head')
                const InputDecorator(
                  decoration: InputDecoration(labelText: 'Sale quantity'),
                  child: Text('1 head'),
                )
              else if (line.type == 'livestock' && line.unit == 'kg')
                _numberField(line.quantity, 'Live weight (kg)', required: true)
              else if (line.type == 'livestock_batch' && line.unit == 'head')
                _wholeNumberField(
                  line.quantity,
                  'Number of animals',
                  maximum: availableHeads,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        line.quantity,
                        'Total live weight (kg)',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _wholeNumberField(
                        line.headCount,
                        'Heads included',
                        maximum: availableHeads,
                      ),
                    ),
                  ],
                ),
              if (line.unit == 'kg') ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    line.type == 'livestock_batch'
                        ? 'Total = live weight × rate per kg. Batch stock will reduce by heads included.'
                        : 'Total = live weight × rate per kg. The selected animal will be marked sold.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ] else if (line.type == 'livestock' && !widget.isSale)
              const InputDecorator(
                decoration: InputDecoration(labelText: 'Purchase quantity'),
                child: Text('1 head'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      line.quantity,
                      line.type == 'livestock_batch' && !widget.isSale
                          ? 'Number of animals'
                          : line.type == 'livestock_batch'
                          ? 'Sale quantity'
                          : 'Quantity',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('${line.type}-${line.unit}'),
                      initialValue:
                          line.type == 'livestock_batch' && !widget.isSale
                          ? 'head'
                          : line.unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items:
                          ['kg', 'gram', 'litre', 'piece', 'head', 'bag', 'box']
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                      onChanged:
                          line.type == 'livestock_batch' && !widget.isSale
                          ? null
                          : (value) =>
                                setState(() => line.unit = value ?? 'kg'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            _numberField(
              line.price,
              widget.isSale &&
                      (line.type == 'livestock' ||
                          line.type == 'livestock_batch') &&
                      line.unit == 'kg'
                  ? 'Rate per kg'
                  : widget.isSale
                  ? 'Unit sale price'
                  : 'Unit cost',
              required: true,
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}

class InvoicePaymentForm extends StatefulWidget {
  const InvoicePaymentForm({
    super.key,
    required this.api,
    required this.endpoint,
    required this.due,
  });
  final ApiClient api;
  final String endpoint;
  final num due;

  @override
  State<InvoicePaymentForm> createState() => _InvoicePaymentFormState();
}

class _InvoicePaymentFormState extends State<InvoicePaymentForm> {
  final formKey = GlobalKey<FormState>();
  late final amount = TextEditingController(
    text: widget.due.toStringAsFixed(2),
  );
  List<Map<String, dynamic>> accounts = [];
  int? accountId;
  DateTime date = DateTime.now();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      accounts = widget.api.listFrom(await widget.api.get('accounts'));
      accountId = accounts.isEmpty ? null : accounts.first['id'] as int?;
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.api.post(widget.endpoint, {
        'financial_account_id': accountId,
        'amount': num.tryParse(amount.text),
        'payment_date': dateFormat.format(date),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox(height: 200, child: LoadingView());
    return Form(
      key: formKey,
      child: Column(
        children: [
          SearchableDropdown(
            label: 'Cash / bank account',
            items: accounts,
            value: accountId,
            required: true,
            onChanged: (value) => accountId = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              helperText: 'Outstanding: ${moneyFormat.format(widget.due)}',
            ),
            validator: (value) {
              final number = num.tryParse(value ?? '') ?? 0;
              if (number <= 0) return 'Enter an amount';
              if (number > widget.due) {
                return 'Amount cannot exceed outstanding balance';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            title: const Text('Payment date'),
            subtitle: Text(displayDateFormat.format(date)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (selected != null) setState(() => date = selected);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _save,
              child: const Text('Post payment'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }
}

class _TradeLine {
  String type = 'inventory';
  int? referenceId;
  int? speciesId;
  String? sex;
  String unit = 'kg';
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');
  final headCount = TextEditingController(text: '1');
  final batchCode = TextEditingController();
  final breed = TextEditingController();
  final tagNumber = TextEditingController();
  final animalName = TextEditingController();
  final dateOfBirth = TextEditingController();

  void dispose() {
    description.dispose();
    quantity.dispose();
    price.dispose();
    headCount.dispose();
    batchCode.dispose();
    breed.dispose();
    tagNumber.dispose();
    animalName.dispose();
    dateOfBirth.dispose();
  }
}
