import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/session_controller.dart';
import '../widgets/common.dart';
import 'generic/resource_screen.dart';
import 'livestock_detail_screen.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      items = widget.api.listFrom(
        await widget.api.get('livestock-batches', query: {'per_page': 100}),
      );
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static const fields = [
    FieldSpec(
      'farm_id',
      'Farm',
      type: FieldType.lookup,
      lookupPath: 'farms',
      required: true,
    ),
    FieldSpec(
      'species_id',
      'Species',
      type: FieldType.lookup,
      lookupPath: 'species',
      required: true,
    ),
    FieldSpec('batch_code', 'Batch code', required: true),
    FieldSpec('breed', 'Breed'),
    FieldSpec(
      'received_on',
      'Received date',
      type: FieldType.date,
      required: true,
    ),
    FieldSpec(
      'initial_quantity',
      'Opening quantity',
      type: FieldType.number,
      createOnly: true,
      required: true,
    ),
    FieldSpec(
      'average_unit_cost',
      'Average unit cost',
      type: FieldType.number,
      defaultValue: 0,
      required: true,
    ),
    FieldSpec(
      'status',
      'Status',
      type: FieldType.select,
      options: ['active', 'sold_out', 'cancelled'],
      defaultValue: 'active',
      required: true,
    ),
    FieldSpec('notes', 'Notes', type: FieldType.multiline),
  ];

  Future<void> editBatch([Map<String, dynamic>? batch]) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: batch == null ? 'Create livestock batch' : 'Edit livestock batch',
      child: ResourceForm(
        api: widget.api,
        endpoint: 'livestock-batches',
        fields: fields,
        initial: batch,
      ),
    );
    if (saved == true) load();
  }

  Future<void> deleteBatch(Map<String, dynamic> batch) async {
    if (!await confirmAction(
      context,
      'Delete livestock batch',
      'Only an unused manual batch can be deleted.',
    )) {
      return;
    }
    try {
      await widget.api.delete('livestock-batches/${batch['id']}');
      if (mounted) showMessage(context, 'Livestock batch deleted.');
      load();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  Future<void> viewBatch(Map<String, dynamic> batch) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LivestockDetailScreen(
          api: widget.api,
          recordId: batch['id'] as int,
          isBatch: true,
        ),
      ),
    );
    if (mounted) load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Livestock batches',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: editBatch,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 180),
                      const EmptyView(
                        icon: Icons.groups_2_outlined,
                        message: 'No livestock batches found.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final initial =
                          num.tryParse('${item['initial_quantity']}') ?? 0;
                      final current =
                          num.tryParse('${item['current_quantity']}') ?? 0;
                      return GestureDetector(
                        onTap: () => viewBatch(item),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['batch_code']}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    StatusChip('${item['status']}'),
                                    IconButton(
                                      onPressed: () => viewBatch(item),
                                      tooltip: 'View details',
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'More actions',
                                      onSelected: (value) {
                                        if (value == 'view') viewBatch(item);
                                        if (value == 'edit') editBatch(item);
                                        if (value == 'delete') {
                                          deleteBatch(item);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(
                                              Icons.visibility_outlined,
                                            ),
                                            title: Text('View details'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        if (item['purchase_id'] == null)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '${item['species']?['name'] ?? ''} · ${item['breed'] ?? 'No breed'} · ${item['farm']?['name'] ?? ''}',
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: initial == 0
                                      ? 0
                                      : (current / initial).clamp(0, 1),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Started ${item['initial_quantity']} head',
                                    ),
                                    Text(
                                      '${item['current_quantity']} available',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  List<Map<String, dynamic>> animals = [];
  List<Map<String, dynamic>> records = [];
  int? animalId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAnimals();
  }

  Future<void> loadAnimals() async {
    try {
      animals = widget.api.listFrom(
        await widget.api.get('animals', query: {'per_page': 100}),
      );
      animalId ??= animals.isEmpty ? null : animals.first['id'] as int?;
      if (animalId != null) await loadRecords();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadRecords() async {
    if (animalId == null) return;
    records = widget.api.listFrom(
      await widget.api.get('animals/$animalId/health-records'),
    );
    if (mounted) setState(() {});
  }

  Future<void> editRecord([Map<String, dynamic>? record]) async {
    if (animalId == null) return;
    final saved = await AppSheet.show<bool>(
      context,
      title: record == null ? 'Add health record' : 'Edit health record',
      child: ResourceForm(
        api: widget.api,
        endpoint: 'animals/$animalId/health-records',
        updateEndpoint: 'health-records',
        initial: record,
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
      ),
    );
    if (saved == true) loadRecords();
  }

  Future<void> deleteRecord(Map<String, dynamic> record) async {
    if (!await confirmAction(
      context,
      'Delete health record',
      'Delete this medical history entry?',
    )) {
      return;
    }
    try {
      await widget.api.delete('health-records/${record['id']}');
      loadRecords();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: animalId,
                  decoration: const InputDecoration(labelText: 'Animal'),
                  items: animals
                      .map(
                        (animal) => DropdownMenuItem(
                          value: animal['id'] as int,
                          child: Text(
                            '${animal['tag_number']} ${animal['name'] ?? ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    animalId = value;
                    loadRecords();
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: animalId == null ? null : editRecord,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const EmptyView(
                  icon: Icons.medical_services_outlined,
                  message: 'No health records for this animal.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: records.length,
                  itemBuilder: (_, index) {
                    final record = records[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.vaccines_outlined),
                        ),
                        title: Text('${record['title']}'),
                        subtitle: Text(
                          '${record['type']} · ${formatAppDate(record['observed_on'])}\n${record['medicine'] ?? record['treatment'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') editRecord(record);
                            if (value == 'delete') deleteRecord(record);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? report;
  bool loading = true;
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime.now();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      report = widget.api.objectFrom(
        await widget.api.get(
          'reports',
          query: {'from': dateFormat.format(from), 'to': dateFormat.format(to)},
        ),
      );
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    final data = report ?? {};
    final income = data['income_expense'] is Map
        ? Map<String, dynamic>.from(data['income_expense'])
        : <String, dynamic>{};
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _dateButton('From', from, (value) => from = value),
              ),
              const SizedBox(width: 10),
              Expanded(child: _dateButton('To', to, (value) => to = value)),
              IconButton.filled(
                onPressed: load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income vs expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _row('Income', income['income']),
                  _row('Expense', income['expense']),
                  const Divider(),
                  _row('Net profit', income['net_profit'], bold: true),
                ],
              ),
            ),
          ),
          for (final entry in data.entries.where(
            (entry) => entry.key != 'income_expense',
          ))
            Card(
              child: ExpansionTile(
                title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                subtitle: Text(_summary(entry.value)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText('${entry.value}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateButton(
    String label,
    DateTime value,
    ValueChanged<DateTime> change,
  ) => OutlinedButton(
    onPressed: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (selected != null) setState(() => change(selected));
    },
    child: Text('$label ${displayDateFormat.format(value)}'),
  );
  Widget _row(String label, dynamic value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          moneyFormat.format(num.tryParse('$value') ?? 0),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  String _summary(dynamic value) {
    if (value is Map) {
      return value.entries
          .take(3)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' · ');
    }
    return '$value';
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.session});
  final SessionController session;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController controller = TextEditingController(
    text: widget.session.baseUrl,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const SectionHeader(
        title: 'Connection',
        subtitle: 'Laravel API used by this device.',
      ),
      TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'API base URL',
          helperText: 'Example: http://10.0.2.2/.../api/v1',
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () async {
          await widget.session.setBaseUrl(controller.text);
          if (!context.mounted) return;
          showMessage(context, 'API server saved.');
        },
        child: const Text('Save server'),
      ),
      const SizedBox(height: 28),
      const SectionHeader(title: 'Account'),
      Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(widget.session.userName),
          subtitle: Text(widget.session.tenantName),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: widget.session.logout,
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ],
  );
}
