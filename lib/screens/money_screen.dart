import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  List<Map<String, dynamic>> accounts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      accounts = widget.api.listFrom(await widget.api.get('accounts'));
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> showTransfer() async {
    final saved = await AppSheet.show<bool>(
      context,
      title: 'Transfer cash / bank',
      child: TransferForm(api: widget.api, accounts: accounts),
    );
    if (saved == true) load();
  }

  Future<void> showAccount(Map<String, dynamic> account) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AccountStatementScreen(api: widget.api, account: account),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    final total = accounts.fold<num>(
      0,
      (sum, item) => sum + (num.tryParse('${item['current_balance']}') ?? 0),
    );
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available cash & bank'),
                        Text(
                          moneyFormat.format(total),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: showTransfer,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Transfer'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final account in accounts)
            Card(
              child: ListTile(
                onTap: () => showAccount(account),
                leading: CircleAvatar(
                  child: Icon(
                    account['type'] == 'cash'
                        ? Icons.payments_outlined
                        : Icons.account_balance_outlined,
                  ),
                ),
                title: Text(
                  '${account['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${account['type']} · ${account['account_number'] ?? 'No account number'}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      moneyFormat.format(
                        num.tryParse('${account['current_balance']}') ?? 0,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'View statement',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({
    super.key,
    required this.api,
    required this.account,
  });
  final ApiClient api;
  final Map<String, dynamic> account;

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  List<Map<String, dynamic>> transactions = [];
  Map<String, dynamic> account = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await widget.api.get('accounts/${widget.account['id']}');
      account = widget.api.objectFrom(response);
      final raw = response is Map ? response['transactions'] : null;
      transactions = widget.api.listFrom(raw);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.account['name']} statement')),
    body: loading
        ? const LoadingView()
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    title: const Text('Current balance'),
                    trailing: Text(
                      moneyFormat.format(
                        num.tryParse('${account['current_balance']}') ?? 0,
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  const SizedBox(
                    height: 300,
                    child: EmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'No account transactions yet.',
                    ),
                  ),
                for (final transaction in transactions)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction['direction'] == 'in'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.errorContainer,
                        child: Icon(
                          transaction['direction'] == 'in'
                              ? Icons.south_west
                              : Icons.north_east,
                        ),
                      ),
                      title: Text(
                        '${transaction['description'] ?? transaction['type']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${formatAppDate(transaction['transaction_date'])} · Balance ${moneyFormat.format(num.tryParse('${transaction['running_balance']}') ?? 0)}',
                      ),
                      trailing: Text(
                        '${transaction['direction'] == 'in' ? '+' : '-'}${moneyFormat.format(num.tryParse('${transaction['amount']}') ?? 0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: transaction['direction'] == 'in'
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class TransferForm extends StatefulWidget {
  const TransferForm({super.key, required this.api, required this.accounts});
  final ApiClient api;
  final List<Map<String, dynamic>> accounts;

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final notes = TextEditingController();
  int? fromId;
  int? toId;
  DateTime date = DateTime.now();
  bool saving = false;

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    if (fromId == toId) {
      showMessage(
        context,
        'Source and destination must be different.',
        error: true,
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.api.post('account-transfers', {
        'from_account_id': fromId,
        'to_account_id': toId,
        'amount': num.tryParse(amount.text),
        'transfer_date': dateFormat.format(date),
        'notes': notes.text.trim(),
      });
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
        SearchableDropdown(
          label: 'From account',
          items: widget.accounts,
          value: fromId,
          required: true,
          onChanged: (value) => fromId = value,
        ),
        const SizedBox(height: 12),
        SearchableDropdown(
          label: 'To account',
          items: widget.accounts,
          value: toId,
          required: true,
          onChanged: (value) => toId = value,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: formFieldLabel('Amount', required: true),
          ),
          validator: (value) =>
              (num.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter an amount' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : save,
            child: const Text('Complete transfer'),
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    amount.dispose();
    notes.dispose();
    super.dispose();
  }
}

class PartyLedgersScreen extends StatefulWidget {
  const PartyLedgersScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<PartyLedgersScreen> createState() => _PartyLedgersScreenState();
}

class _PartyLedgersScreenState extends State<PartyLedgersScreen> {
  List<Map<String, dynamic>> parties = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      parties = widget.api.listFrom(await widget.api.get('contacts'));
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Customer & vendor ledgers',
            subtitle: 'Tap a party to view invoice and payment entries.',
          ),
          if (parties.isEmpty)
            const SizedBox(
              height: 300,
              child: EmptyView(
                icon: Icons.menu_book_outlined,
                message: 'No parties found.',
              ),
            ),
          for (final party in parties)
            Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PartyStatementScreen(api: widget.api, party: party),
                  ),
                ),
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(
                  '${party['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${party['type']} · ${party['phone'] ?? ''}'),
                trailing: Text(
                  moneyFormat.format(
                    (num.tryParse('${party['debit_total']}') ?? 0) -
                        (num.tryParse('${party['credit_total']}') ?? 0),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PartyStatementScreen extends StatefulWidget {
  const PartyStatementScreen({
    super.key,
    required this.api,
    required this.party,
  });
  final ApiClient api;
  final Map<String, dynamic> party;

  @override
  State<PartyStatementScreen> createState() => _PartyStatementScreenState();
}

class _PartyStatementScreenState extends State<PartyStatementScreen> {
  List<Map<String, dynamic>> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await widget.api.get('contacts/${widget.party['id']}');
      entries = widget.api.listFrom(
        response is Map ? response['ledger'] : null,
      );
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.party['name']} ledger')),
    body: loading
        ? const LoadingView()
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (entries.isEmpty)
                  const SizedBox(
                    height: 300,
                    child: EmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'No ledger entries yet.',
                    ),
                  ),
                for (final entry in entries)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          (num.tryParse('${entry['debit']}') ?? 0) > 0
                              ? Icons.north_east
                              : Icons.south_west,
                        ),
                      ),
                      title: Text(
                        '${entry['entry_type']}'.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${formatAppDate(entry['entry_date'])} · ${entry['reference_number'] ?? 'No reference'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Dr ${moneyFormat.format(num.tryParse('${entry['debit']}') ?? 0)}',
                          ),
                          Text(
                            'Cr ${moneyFormat.format(num.tryParse('${entry['credit']}') ?? 0)}',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class QuickOperationsScreen extends StatelessWidget {
  const QuickOperationsScreen({super.key, required this.api});
  final ApiClient api;

  Future<void> _open(BuildContext context, String mode) async {
    await AppSheet.show<bool>(
      context,
      title: switch (mode) {
        'receipt' => 'Receive from customer',
        'payment' => 'Pay vendor',
        _ => 'Record inventory movement',
      },
      child: mode == 'stock'
          ? InventoryMovementForm(api: api)
          : PartyPaymentForm(
              api: api,
              mode: mode == 'receipt' ? 'customer_receipt' : 'vendor_payment',
            ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const SectionHeader(
        title: 'Quick operations',
        subtitle: 'Post common transactions with cash/bank validation.',
      ),
      _tile(
        context,
        Icons.call_received,
        'Receive money',
        'Post a customer receipt and update party ledger.',
        () => _open(context, 'receipt'),
      ),
      _tile(
        context,
        Icons.call_made,
        'Pay vendor',
        'Pay a supplier and update account and party ledger.',
        () => _open(context, 'payment'),
      ),
      _tile(
        context,
        Icons.move_down_outlined,
        'Inventory movement',
        'Stock in, usage, wastage or manual adjustment.',
        () => _open(context, 'stock'),
      ),
    ],
  );

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback tap,
  ) => Card(
    child: ListTile(
      onTap: tap,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class PartyPaymentForm extends StatefulWidget {
  const PartyPaymentForm({super.key, required this.api, required this.mode});
  final ApiClient api;
  final String mode;

  @override
  State<PartyPaymentForm> createState() => _PartyPaymentFormState();
}

class _PartyPaymentFormState extends State<PartyPaymentForm> {
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final reference = TextEditingController();
  List<Map<String, dynamic>> parties = [];
  List<Map<String, dynamic>> accounts = [];
  int? partyId;
  int? accountId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await Future.wait([
        widget.api.get('contacts'),
        widget.api.get('accounts'),
      ]);
      parties = widget.api.listFrom(result[0]).where((item) {
        final type = item['type'];
        return type == 'both' ||
            type == (widget.mode == 'customer_receipt' ? 'customer' : 'vendor');
      }).toList();
      accounts = widget.api.listFrom(result[1]);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    try {
      await widget.api.post('contact-payments', {
        'contact_id': partyId,
        'financial_account_id': accountId,
        'mode': widget.mode,
        'amount': num.tryParse(amount.text),
        'payment_date': dateFormat.format(DateTime.now()),
        'reference': reference.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox(height: 240, child: LoadingView());
    return Form(
      key: key,
      child: Column(
        children: [
          SearchableDropdown(
            label: widget.mode == 'customer_receipt' ? 'Customer' : 'Vendor',
            items: parties,
            value: partyId,
            required: true,
            onChanged: (value) => partyId = value,
          ),
          const SizedBox(height: 12),
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
              labelText: formFieldLabel('Amount', required: true),
            ),
            validator: (value) => (num.tryParse(value ?? '') ?? 0) <= 0
                ? 'Enter an amount'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: reference,
            decoration: const InputDecoration(labelText: 'Reference'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: save,
              child: const Text('Post transaction'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amount.dispose();
    reference.dispose();
    super.dispose();
  }
}

class InventoryMovementForm extends StatefulWidget {
  const InventoryMovementForm({super.key, required this.api});
  final ApiClient api;
  @override
  State<InventoryMovementForm> createState() => _InventoryMovementFormState();
}

class _InventoryMovementFormState extends State<InventoryMovementForm> {
  final key = GlobalKey<FormState>();
  final quantity = TextEditingController();
  final cost = TextEditingController(text: '0');
  final notes = TextEditingController();
  List<Map<String, dynamic>> items = [];
  int? itemId;
  String type = 'consumption';
  String direction = 'out';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      items = widget.api.listFrom(await widget.api.get('inventory-items'));
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    try {
      await widget.api.post('inventory-items/$itemId/movements', {
        'type': type,
        'direction': direction,
        'quantity': num.tryParse(quantity.text),
        'unit_cost': num.tryParse(cost.text) ?? 0,
        'occurred_on': dateFormat.format(DateTime.now()),
        'notes': notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox(height: 240, child: LoadingView());
    return Form(
      key: key,
      child: Column(
        children: [
          SearchableDropdown(
            label: 'Inventory item',
            items: items,
            value: itemId,
            required: true,
            onChanged: (value) => itemId = value,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: InputDecoration(
              labelText: formFieldLabel('Movement type', required: true),
            ),
            items:
                ['purchase', 'consumption', 'wastage', 'return', 'adjustment']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() {
              type = value ?? 'consumption';
              direction = ['purchase', 'return'].contains(type) ? 'in' : 'out';
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: direction,
            decoration: InputDecoration(
              labelText: formFieldLabel('Direction', required: true),
            ),
            items: const [
              DropdownMenuItem(value: 'in', child: Text('Stock in')),
              DropdownMenuItem(value: 'out', child: Text('Stock out')),
            ],
            onChanged: (value) => direction = value ?? 'out',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: formFieldLabel('Quantity', required: true),
            ),
            validator: (value) =>
                (num.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter quantity' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Unit cost'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: save,
              child: const Text('Post movement'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    quantity.dispose();
    cost.dispose();
    notes.dispose();
    super.dispose();
  }
}
