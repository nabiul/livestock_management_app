import 'package:flutter/material.dart';

import '../core/session_controller.dart';
import 'access_screen.dart';
import 'dashboard_screen.dart';
import 'money_screen.dart';
import 'operations_screens.dart';
import 'report_design_screen.dart';
import 'resource_modules.dart';
import 'trade_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final SessionController session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int selected = 0;

  List<_Destination> get destinations {
    final api = widget.session.api;
    final all = [
      _Destination(
        'Dashboard',
        Icons.dashboard_outlined,
        'dashboard',
        () => DashboardScreen(api: api),
      ),
      _Destination(
        'Reports',
        Icons.analytics_outlined,
        'reports',
        () => ProfessionalReportsScreen(api: api),
      ),
      _Destination(
        'Farms',
        Icons.home_work_outlined,
        'farms',
        () => farmsModule(api),
      ),
      _Destination(
        'Livestock',
        Icons.pets_outlined,
        'livestock',
        () => animalsModule(api),
      ),
      _Destination(
        'Livestock batches',
        Icons.groups_2_outlined,
        'livestock',
        () => BatchesScreen(api: api),
      ),
      _Destination(
        'Health',
        Icons.medical_services_outlined,
        'health',
        () => HealthScreen(api: api),
      ),
      _Destination(
        'Inventory',
        Icons.inventory_2_outlined,
        'inventory',
        () => inventoryModule(api),
      ),
      _Destination(
        'Production',
        Icons.egg_alt_outlined,
        'production',
        () => productionModule(api),
      ),
      _Destination(
        'Sales POS',
        Icons.point_of_sale_outlined,
        'sales',
        () => TradesScreen(api: api, isSale: true),
      ),
      _Destination(
        'Purchase POS',
        Icons.shopping_cart_outlined,
        'purchases',
        () => TradesScreen(api: api, isSale: false),
      ),
      _Destination(
        'Parties',
        Icons.people_alt_outlined,
        'contacts',
        () => contactsModule(api),
      ),
      _Destination(
        'Party ledgers',
        Icons.menu_book_outlined,
        'contacts',
        () => PartyLedgersScreen(api: api),
      ),
      _Destination(
        'Cash & bank setup',
        Icons.account_balance_wallet_outlined,
        'accounts',
        () => accountsModule(api),
      ),
      _Destination(
        'Statements & transfer',
        Icons.swap_horiz,
        'accounts',
        () => MoneyScreen(api: api),
      ),
      _Destination(
        'Quick operations',
        Icons.bolt_outlined,
        null,
        () => QuickOperationsScreen(api: api),
        anyOf: const ['contacts', 'inventory'],
      ),
      _Destination(
        'Accounting',
        Icons.receipt_long_outlined,
        'accounting',
        () => accountingModule(api),
      ),
      _Destination(
        'Categories',
        Icons.category_outlined,
        'accounting',
        () => categoriesModule(api),
      ),
      _Destination(
        'Users & roles',
        Icons.manage_accounts_outlined,
        'users',
        () => AccessScreen(api: api),
      ),
      _Destination(
        'Settings',
        Icons.settings_outlined,
        null,
        () => SettingsScreen(session: widget.session),
      ),
    ];
    return all.where((item) {
      if (item.permission != null) return widget.session.can(item.permission!);
      if (item.anyOf.isNotEmpty) return item.anyOf.any(widget.session.can);
      return true;
    }).toList();
  }

  void select(int index) {
    setState(() => selected = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = destinations;
    if (selected >= items.length) selected = 0;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final content = KeyedSubtree(
      key: ValueKey('${items[selected].title}-$selected'),
      child: items[selected].builder(),
    );
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.agriculture,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LivestockOS',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  items[selected].title,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!wide)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CircleAvatar(
                child: Text(
                  widget.session.userName.isEmpty
                      ? 'U'
                      : widget.session.userName[0].toUpperCase(),
                ),
              ),
            ),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: _navigation(items))),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 270,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: SafeArea(top: false, child: _navigation(items)),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _navigation(List<_Destination> items) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                widget.session.userName.isEmpty
                    ? 'U'
                    : widget.session.userName[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.userName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.session.tenantName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const Divider(),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: items.length,
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ListTile(
              selected: selected == index,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(items[index].icon),
              title: Text(
                items[index].title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => select(index),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.session.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ),
      ),
    ],
  );
}

class _Destination {
  const _Destination(
    this.title,
    this.icon,
    this.permission,
    this.builder, {
    this.anyOf = const [],
  });
  final String title;
  final IconData icon;
  final String? permission;
  final Widget Function() builder;
  final List<String> anyOf;
}
